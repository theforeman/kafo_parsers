# encoding: utf-8
require 'test_helper'
require 'kafo_parsers/puppet_module_parser'

module KafoParsers
  describe PuppetModuleParser do
    describe ".parse(class)" do
      # we skip tests for this parser if puppet 4.0.0+ is installed
      next if Gem::Specification.find_all_by_name('puppet').sort_by(&:version).last.version >= Gem::Version.new('4.0.0')

      { 'hostclass' => BASIC_MANIFEST, 'definition' => DEFINITION_MANIFEST }.each_pair do |type, manifest|

        data = PuppetModuleParser.parse(ManifestFileFactory.build(manifest).path)

        describe 'data structure' do
          let(:keys) { data.keys }
          specify { keys.must_include :values }
          specify { keys.must_include :validations }
          specify { keys.must_include :docs }
          specify { keys.must_include :parameters }
          specify { keys.must_include :types }
          specify { keys.must_include :groups }
          specify { keys.must_include :conditions }
          specify { keys.must_include :object_type }
        end

        describe 'object_type' do
          specify { data[:object_type].must_equal type }
        end

        let(:parameters) { data[:parameters] }
        describe 'parsed parameters' do
          specify { parameters.must_include 'version' }
          specify { parameters.must_include 'sub_version' }
          specify { parameters.must_include 'undocumented' }
          specify { parameters.must_include 'undef' }
          specify { parameters.must_include 'debug' }
          specify { parameters.wont_include 'documented' }
        end

        describe "parsed values" do
          let(:values) { data[:values] }
          it 'includes values for all parameters' do
            parameters.each { |p| values.keys.must_include p }
          end
          specify { values['version'].must_equal '1.0' }
          specify { values['sub_version'].must_equal 'beta' }
          specify { values['undef'].must_equal :undef }
          specify { values['debug'].must_equal true }
        end

        describe "parsed validations" do
          let(:validations) { data[:validations] }
          specify { validations.size.must_equal 1 }
          specify { validations.map(&:name).each { |v| v.must_equal 'validate_string' } }
          specify { validations.map(&:arguments).must_equal [['$undocumented']] }
          specify { validations.each { |v| v.must_be_kind_of KafoParsers::Validation } }
        end

        describe "parsed documentation" do
          let(:docs) { data[:docs] }
          specify { docs.keys.must_include 'documented' }
          specify { docs.keys.must_include 'version' }
          specify { docs.keys.must_include 'undef' }
          specify { docs.keys.wont_include 'm_i_a' }
          specify { docs.keys.wont_include 'undocumented' }
          specify { docs['version'].must_equal ['some version number'] }
          specify { docs['multiline'].must_equal ['param with multiline', 'documentation', 'consisting of 3 lines'] }
          specify { docs['typed'].wont_include 'type:bool' }
        end

        describe "parsed groups" do
          let(:groups) { data[:groups] }
          specify { groups['version'].must_equal ['Parameters'] }
          specify { groups['debug'].must_equal ['Advanced parameters'] }
          specify { groups['server'].must_equal ['Advanced parameters', 'MySQL'] }
          specify { groups['file'].must_equal ['Advanced parameters', 'Sqlite'] }
          specify { groups['log_level'].must_equal ['Extra parameters'] }
        end

        describe "parsed types" do
          let(:types) { data[:types] }
          specify { types['version'].must_equal 'string' }
          specify { types['typed'].must_equal 'boolean' }
          specify { types['remote'].must_equal 'boolean' }
        end

        describe "parsed conditions" do
          let(:conditions) { data[:conditions] }
          specify { conditions['version'].must_be_nil }
          specify { conditions['typed'].must_be_nil }
          specify { conditions['remote'].must_equal '$db_type == \'mysql\'' }
          specify { conditions['server'].must_equal '$db_type == \'mysql\' && $remote' }
          specify { conditions['username'].must_equal '$db_type == \'mysql\'' }
          specify { conditions['password'].must_equal '$db_type == \'mysql\' && $username != \'root\'' }
        end
      end

      describe 'with UTF-8 manifest' do
        let(:manifest) { "# e✗amp✓e\n" + BASIC_MANIFEST.sub('class testing(', 'class testingutf8(') }
        let(:data) { PuppetModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:parameters) { data[:parameters] }
        specify { parameters.must_include 'version' }
      end

      describe "parsing complex validations" do
        let(:manifest) { "class test#{validators.hash}($test) {\n#{validators}\n}\n" }
        let(:data) { PuppetModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:validations) { data[:validations] }

        describe "validate_integer" do
          let(:validators) { %{validate_integer($test, undef, 1)} }
          specify { validations.size.must_equal 1 }
          specify { validations.map(&:name).must_equal ['validate_integer'] }
          specify { validations.map(&:arguments).must_equal [['$test', :undef, '1']] }
          specify { validations.each { |v| v.must_be_kind_of KafoParsers::Validation } }
        end

        describe "validate_re" do
          let(:validators) { %{validate_re($test, ["^mysql$", "^sqlite$"], "invalid $test DB type")} }
          specify { validations.size.must_equal 1 }
          specify { validations.map(&:name).must_equal ['validate_re'] }
          specify { validations.map(&:arguments).must_equal [['$test', ['^mysql$', '^sqlite$'], 'invalid $test DB type']] }
          specify { validations.each { |v| v.must_be_kind_of KafoParsers::Validation } }
        end
      end
    end
  end
end
