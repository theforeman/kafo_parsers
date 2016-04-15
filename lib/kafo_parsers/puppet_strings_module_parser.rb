# encoding: UTF-8
require 'json'
require 'kafo_parsers/doc_parser'

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
        :validations => content.validations
      }
      data[:parameters] = data[:values].keys
      data.merge!(docs)
      data
    end

    def self.available?
      `#{puppet_bin} help strings 2>&1`
      if $?.success?
        return true
      else
        raise KafoParsers::ParserNotAvailable.new("#{puppet_bin} does not have strings module installed")
      end
    end

    def initialize(file)
      @file = file
      raise KafoParsers::ModuleName, "File not found #{file}, check your answer file" unless File.exists?(file)

      command = "#{self.class.puppet_bin} strings #{file} --emit-json-stdout"
      @raw_json = `#{command}`
      unless $?.success?
        raise KafoParsers::ParseError, "'#{command}' returned error\n#{@raw_json}"
      end

      begin
        @complete_hash = ::JSON.parse(@raw_json)
      rescue ::JSON::ParserError => e
        raise KafoParsers::ParseError, "'#{command}' returned invalid json output: #{e.message}\n#{@raw_json}"
      end
      self.data_type # we need to determine data_type before any further parsing

      self
    end

    # AIO and system default puppet bins are tested for existence, fallback to just `puppet` otherwise
    def self.puppet_bin
      @puppet_bin ||= begin
        found_puppet_path = (::ENV['PATH'].split(File::PATH_SEPARATOR) + ['/opt/puppetlabs/bin']).find do |path|
          binary = File.join(path, 'puppet')
          binary if File.executable?(binary)
        end
        File.join(found_puppet_path, 'puppet') || 'puppet'
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
      Hash[@parsed_hash['parameters'].map { |name, value| [ name, sanitize(value) ] }]
    end

    # unsupported in puppet strings parser
    def validations(param = nil)
      []
    end

    # returns data in following form
    # {
    #   :docs => { $param1 => 'documentation without types and conditions'}
    #   :types => { $param1 => 'boolean'},
    #   :groups => { $param1 => ['Parameters', 'Advanced']},
    #   :conditions => { $param1 => '$db_type == "mysql"'},
    # }
    def docs
      data = { :docs => {}, :types => {}, :groups => {}, :conditions => {} }
      if @parsed_hash.nil?
        raise KafoParsers::DocParseError, "no documentation found for manifest #{@file}, parsing error?"
      elsif !@parsed_hash['docstring'].nil?
        parser             = DocParser.new(@parsed_hash['docstring']).parse
        data[:docs]        = parser.docs
        data[:groups]      = parser.groups
        data[:types]       = parser.types
        data[:conditions]  = parser.conditions
      end
      data
    end

    private

    # default values using puppet strings includes $ symbol, e.g. "$::foreman::params::ssl"
    # to keep the same API we strip $ if it's present
    #
    # values are reported as strings which is issue especially for :under
    # strings are double quoted
    # others must be typecast manually according to reported type
    def sanitize(value)
      if (value.start_with?("'") && value.end_with?("'")) || (value.start_with?('"') && value.end_with?('"'))
        value = value[1..-2]
      end
      value = value[1..-1] if value.start_with?('$')
      value = :undef if value == 'undef'

      value
    end
  end
end
