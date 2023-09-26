# encoding: UTF-8
require 'json'
require 'open3'

require 'kafo_parsers/doc_parser'
require 'kafo_parsers/param_doc_parser'

module KafoParsers
  class PuppetStringsModuleParser
    # You can call this method to get all supported information from a given manifest
    #
    # @param [ String ] manifest file path to parse
    # @return [ Hash ] hash containing values, validations, documentation, types, groups and conditions
    def self.parse(file)
      content = new(file)
      docs    = content.docs

      # data_type must be called before other validations
      data = {
        :object_type => content.data_type,
        :values      => content.values,
        :validations => content.validations,
        :source      => content.source
      }
      data[:parameters] = data[:values].keys
      data.merge!(docs)
      data
    end

    def self.available?
      _stdout, _stderr, status = run_puppet(['help', 'strings'])
      if status.success?
        return true
      else
        raise KafoParsers::ParserNotAvailable.new("#{puppet_bin} does not have strings module installed.")
      end
    end

    def initialize(file)
      @file = file = File.expand_path(file)
      raise KafoParsers::ModuleName, "File not found #{file}, check your answer file" unless File.exist?(file)

      command = ['strings', 'generate', '--format', 'json', file]
      @raw_json, stderr, status = self.class.run_puppet(command)

      unless status.success?
        raise KafoParsers::ParseError, "'#{command}' returned error:\n  #{@raw_json}\n  #{stderr}"
      end

      begin
        @complete_hash = ::JSON.parse(@raw_json)
      rescue ::JSON::ParserError => e
        raise KafoParsers::ParseError, "'#{command}' returned invalid json output: #{e.message}\n#{@raw_json}"
      end
      self.data_type # we need to determine data_type before any further parsing

      self
    end

    def source
      @parsed_hash['source']
    end

    # AIO and system default puppet bins are tested for existence, fallback to just `puppet` otherwise
    def self.puppet_bin
      @puppet_bin ||= begin
        found_puppet_path = (::ENV['PATH'].split(File::PATH_SEPARATOR) + ['/opt/puppetlabs/bin']).find do |path|
          binary = File.join(path, 'puppet')
          binary if File.executable?(binary)
        end
        found_puppet_path.nil? ? 'puppet' : File.join(found_puppet_path, 'puppet')
      end
    end

    def data_type
      @data_type ||= begin
        if (@parsed_hash = @complete_hash['puppet_classes'].find { |klass| klass['file'] == @file })
          'hostclass'
        elsif (@parsed_hash = @complete_hash['defined_types'].find { |klass| klass['file'] == @file })
          'definition'
        else
          raise KafoParsers::ParseError, "unable to find manifest data, syntax error in manifest #{@file}?"
        end
      end
    end

    def values
      Hash[
        # combine known parameters (from tags) with any defaults provided
        tag_params.select { |param| !param['types'].nil? }.map { |param| [ param['name'], nil ] } +
          @parsed_hash.fetch('defaults', {}).map { |name, value| [ name, value.nil? ? nil : sanitize(value) ] }
      ]
    end

    # unsupported in puppet strings parser
    def validations(param = nil)
      []
    end

    # returns data in following form
    # {
    #   :docs => { $param1 => ['documentation without types and conditions']}
    #   :types => { $param1 => 'boolean'},
    #   :groups => { $param1 => ['Parameters', 'Advanced']},
    #   :conditions => { $param1 => '$db_type == "mysql"'},
    # }
    def docs
      data = { :docs => {}, :types => {}, :groups => {}, :conditions => {} }
      if @parsed_hash.nil?
        raise KafoParsers::DocParseError, "no documentation found for manifest #{@file}, parsing error?"
      elsif !@parsed_hash['docstring'].nil? && !@parsed_hash['docstring']['text'].nil?
        # Lowest precedence: types given in the strings hash from class definition
        tag_params.each do |param|
          data[:types][param['name']] = param['types'][0] unless param['types'].nil?
        end

        # Next: types and other data from RDoc parser
        rdoc_parser = DocParser.new(@parsed_hash['docstring']['text']).parse
        data[:docs] = rdoc_parser.docs
        data[:groups] = rdoc_parser.groups
        data[:conditions] = rdoc_parser.conditions
        data[:types].merge! rdoc_parser.types

        # Highest precedence: data in YARD @param stored in the 'text' field
        tag_params.each do |param|
          param_name = param['name']
          unless param['text'].nil? || param['text'].empty?
            param_parser = ParamDocParser.new(param_name, param['text'].split($/))
            data[:docs][param_name] = param_parser.doc if param_parser.doc
            data[:groups][param_name] = param_parser.group if param_parser.group
            data[:conditions][param_name] = param_parser.condition if param_parser.condition
            data[:types][param_name] = param_parser.type if param_parser.type
          end
        end
      end
      data
    end

    private

    def self.search_puppet_path(bin_name)
      # Find the location of the puppet executable and use that to
      # determine the path of all executables
      bin_path = (::ENV['PATH'].split(File::PATH_SEPARATOR) + ['/opt/puppetlabs/bin']).find do |path|
        File.executable?(File.join(path, 'puppet')) && File.executable?(File.join(path, bin_name))
      end
      File.join([bin_path, bin_name].compact)
    end

    def self.is_aio_puppet?
      puppet_command = search_puppet_path('puppet')
      File.realpath(puppet_command).start_with?('/opt/puppetlabs')
    rescue Errno::ENOENT
      false
    end

    def self.run_puppet(command)
      command = command.unshift(self.puppet_bin)

      if is_aio_puppet?
        Open3.capture3(clean_env_vars, *command, :unsetenv_others => true)
      else
        Open3.capture3(::ENV, *command, :unsetenv_others => false)
      end
    end

    def self.clean_env_vars
      # Cleaning ENV vars and keeping required vars only because,
      # When using SCL it adds GEM_HOME and GEM_PATH ENV vars.
      whitelisted_vars = %w[HOME USER LANG]

      cleaned_env = ::ENV.select { |var| whitelisted_vars.include?(var) || var.start_with?('LC_') }
      cleaned_env['PATH'] = '/sbin:/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin'
      cleaned_env
    end

    # default values using puppet strings includes $ symbol, e.g. "$::foreman::params::ssl"
    #
    # values are reported as strings which is issue especially for :under
    # strings are double quoted
    # basic array and hashes are supported
    # others must be typecast manually according to reported type
    def sanitize(value)
      if (value.start_with?("'") && value.end_with?("'")) || (value.start_with?('"') && value.end_with?('"'))
        value = value[1..-2]
      elsif value.start_with?('[') && value.end_with?(']')
        # TODO: handle commas in strings like ["a,b", "c"]
        value = value[1..-2].split(',').map { |v| sanitize(v.strip) }
      elsif value.start_with?('{') && value.end_with?('}')
        # TODO: handle commas and => in strings, like {"key" => "value,=>"}
        value = value[1..-2].split(',').map do |v|
          split = v.strip.split('=>')
          raise 'Invalid hash' unless split.length == 2
          split.map { |s| sanitize(s.strip) }
        end.to_h
      end
      value = :undef if value == 'undef'

      value
    end

    def tag_params
      if @parsed_hash['docstring']['tags']
        @parsed_hash['docstring']['tags'].select { |tag| tag['tag_name'] == 'param' }
      else
        []
      end
    end

  end
end
