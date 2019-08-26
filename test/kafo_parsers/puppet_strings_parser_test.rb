# encoding: utf-8
require 'test_helper'
require 'kafo_parsers/puppet_strings_module_parser'

module KafoParsers
  describe PuppetStringsModuleParser do
    describe ".parse(class)" do
      # we skip tests for this parser if puppet-strings is not installed
      next if Gem::Specification.find_all_by_name('puppet-strings').empty?

      [
        {:name => 'RDoc class', :type => 'hostclass', :content => BASIC_MANIFEST},
        {:name => 'YARD class', :type => 'hostclass', :content => BASIC_YARD_MANIFEST},
        {:name => 'RDoc define', :type => 'definition', :content => DEFINITION_MANIFEST}
      ].each do |manifest|
        describe manifest[:name] do
          data = PuppetStringsModuleParser.parse(ManifestFileFactory.build(manifest[:content]).path)

          describe 'data structure' do
            let(:keys) { data.keys }
            specify { _(keys).must_include :values }
            specify { _(keys).must_include :docs }
            specify { _(keys).must_include :parameters }
            specify { _(keys).must_include :types }
            specify { _(keys).must_include :groups }
            specify { _(keys).must_include :conditions }
            specify { _(keys).must_include :object_type }
          end

          describe 'object_type' do
            specify { _(data[:object_type]).must_equal manifest[:type] }
          end

          let(:parameters) { data[:parameters] }
          describe 'parsed parameters' do
            specify { _(parameters).must_include 'required' }
            specify { _(parameters).must_include 'version' }
            specify { _(parameters).must_include 'sub_version' }
            specify { _(parameters).must_include 'undocumented' }
            specify { _(parameters).must_include 'undef' }
            specify { _(parameters).must_include 'debug' }
            specify { _(parameters).wont_include 'documented' }
          end

          describe "parsed values" do
            let(:values) { data[:values] }
            it 'includes values for all parameters' do
              parameters.each { |p| _(values.keys).must_include p }
            end
            specify { _(values['required']).must_be_nil }
            specify { _(values['version']).must_equal '1.0' }
            specify { _(values['sub_version']).must_equal 'beta' }
            specify { _(values['undef']).must_equal :undef }
            specify { _(values['multivalue']).must_equal ['x', 'y'] }
            specify { _(values['mapped']).must_equal({'apples' => 'oranges', 'unquoted' => :undef}) }
            specify { _(values['debug']).must_equal 'true' }
            specify { _(values['variable']).must_equal '$::testing::params::variable' }
          end

          describe "parsed documentation" do
            let(:docs) { data[:docs] }
            specify { _(docs.keys).must_include 'documented' }
            specify { _(docs.keys).must_include 'version' }
            specify { _(docs.keys).must_include 'undef' }
            specify { _(docs.keys).wont_include 'm_i_a' }
            specify { _(docs.keys).wont_include 'undocumented' }
            specify { _(docs['version']).must_equal ['some version number'] }
            specify { _(docs['multiline']).must_equal ['param with multiline', 'documentation', 'consisting of 3 lines'] }
            specify { _(docs['typed']).wont_include 'type:bool' }
          end

          describe "parsed groups" do
            let(:groups) { data[:groups] }
            specify do
              skip "No default grouping of YARD parameters" if manifest[:name] == "YARD class"
              _(groups['version']).must_equal ['Parameters']
            end
            specify { _(groups['debug']).must_equal ['Advanced parameters'] }
            specify { _(groups['server']).must_equal ['Advanced parameters', 'MySQL'] }
            specify { _(groups['file']).must_equal ['Advanced parameters', 'Sqlite'] }
            specify { _(groups['log_level']).must_equal ['Extra parameters'] }
          end

          describe "parsed types" do
            let(:types) { data[:types] }
            specify { _(types['version']).must_equal 'Any' }
            specify { _(types['typed']).must_equal 'boolean' }
            specify { _(types['remote']).must_equal 'boolean' }
            specify { _(types['multivalue']).must_match /^(array|Array\[String\])$/ }
            specify { _(types['mapped']).must_match /^(hash|Hash\[String, Variant\[String, Integer\]\])$/ }
          end

          describe "parsed conditions" do
            let(:conditions) { data[:conditions] }
            specify { _(conditions['version']).must_be_nil }
            specify { _(conditions['typed']).must_be_nil }
            if manifest[:name] == "YARD class"
              specify { _(conditions['remote']).must_be_nil }
              specify { _(conditions['server']).must_equal '$remote' }
              specify { _(conditions['username']).must_be_nil }
              specify { _(conditions['password']).must_equal '$username != \'root\'' }
            else
              specify { _(conditions['remote']).must_equal '$db_type == \'mysql\'' }
              specify { _(conditions['server']).must_equal '$db_type == \'mysql\' && $remote' }
              specify { _(conditions['username']).must_equal '$db_type == \'mysql\'' }
              specify { _(conditions['password']).must_equal '$db_type == \'mysql\' && $username != \'root\'' }
            end
          end
        end
      end

      describe 'with UTF-8 manifest' do
        let(:manifest) { "# e✗amp✓e\n" + BASIC_MANIFEST.sub('class testing(', 'class testingutf8(') }
        let(:data) { PuppetStringsModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:parameters) { data[:parameters] }
        specify { _(parameters).must_include 'version' }
      end

      describe 'with no class parameters' do
        let(:manifest) { "class testing { }" }
        let(:data) { PuppetStringsModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:parameters) { data[:parameters] }
        specify { _(parameters).must_equal [] }
      end

      describe 'with relative path' do
        let(:manifest) { BASIC_MANIFEST.sub('class testing(', 'class relative(') }
        let(:data) do
          path = Pathname.new(ManifestFileFactory.build(manifest).path).relative_path_from(Pathname.new(Dir.pwd))
          PuppetStringsModuleParser.parse(path.to_s)
        end
        let(:parameters) { data[:parameters] }
        specify { _(parameters).must_include 'version' }
      end
    end

    describe '.is_aio_puppet?' do
      subject do
        PuppetStringsModuleParser.stub(:run_puppet, puppet_command) do
          PuppetStringsModuleParser.is_aio_puppet?
        end
      end

      describe 'with an absolute path' do
        let(:puppet_command) { '/usr/bin/puppet' }

        specify 'as a real file' do
          File.stub(:realpath, ->(path) { path }) do
            refute subject
          end
        end

        specify 'as a symlink to AIO' do
          File.stub(:realpath, '/opt/puppetlabs/puppet/bin/wrapper.sh') do
            assert subject
          end
        end

        specify 'as a broken symlink' do
          File.stub(:realpath, ->(path) { raise Errno::ENOENT, 'No such file or directory' }) do
            refute subject
          end
        end
      end

      describe 'with a relative path' do
        let(:puppet_command) { 'puppet' }

        specify 'non-existant' do
          File.stub(:realpath, ->(path) { raise Errno::ENOENT, 'No such file or directory' }) do
            refute subject
          end
        end
      end
    end
  end
end
