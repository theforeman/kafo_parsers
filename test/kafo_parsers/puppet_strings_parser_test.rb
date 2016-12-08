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
            specify { data[:object_type].must_equal manifest[:type] }
          end

          let(:parameters) { data[:parameters] }
          describe 'parsed parameters' do
            specify { parameters.must_include 'required' }
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
            specify { values['required'].must_be_nil }
            specify { values['version'].must_equal '1.0' }
            specify { values['sub_version'].must_equal 'beta' }
            specify { values['undef'].must_equal :undef }
            specify { values['debug'].must_equal 'true' }
            specify { values['variable'].must_equal '$::testing::params::variable' }
          end

          describe "parsed validations are not supported" do
            let(:validations) { data[:validations] }
            specify { validations.must_be_empty }
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
            specify do
              skip "No default grouping of YARD parameters" if manifest[:name] == "YARD class"
              groups['version'].must_equal ['Parameters']
            end
            specify { groups['debug'].must_equal ['Advanced parameters'] }
            specify { groups['server'].must_equal ['Advanced parameters', 'MySQL'] }
            specify { groups['file'].must_equal ['Advanced parameters', 'Sqlite'] }
            specify { groups['log_level'].must_equal ['Extra parameters'] }
          end

          describe "parsed types" do
            let(:types) { data[:types] }
            specify { types['version'].must_equal 'Any' }
            specify { types['typed'].must_equal 'boolean' }
            specify { types['remote'].must_equal 'boolean' }
          end

          describe "parsed conditions" do
            let(:conditions) { data[:conditions] }
            specify { conditions['version'].must_be_nil }
            specify { conditions['typed'].must_be_nil }
            if manifest[:name] == "YARD class"
              specify { conditions['remote'].must_be_nil }
              specify { conditions['server'].must_equal '$remote' }
              specify { conditions['username'].must_be_nil }
              specify { conditions['password'].must_equal '$username != \'root\'' }
            else
              specify { conditions['remote'].must_equal '$db_type == \'mysql\'' }
              specify { conditions['server'].must_equal '$db_type == \'mysql\' && $remote' }
              specify { conditions['username'].must_equal '$db_type == \'mysql\'' }
              specify { conditions['password'].must_equal '$db_type == \'mysql\' && $username != \'root\'' }
            end
          end
        end
      end

      describe 'with UTF-8 manifest' do
        let(:manifest) { "# e✗amp✓e\n" + BASIC_MANIFEST.sub('class testing(', 'class testingutf8(') }
        let(:data) { PuppetStringsModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:parameters) { data[:parameters] }
        specify { parameters.must_include 'version' }
      end

      describe 'with no class parameters' do
        let(:manifest) { "class testing { }" }
        let(:data) { PuppetStringsModuleParser.parse(ManifestFileFactory.build(manifest).path) }
        let(:parameters) { data[:parameters] }
        specify { parameters.must_equal [] }
      end

      describe 'with relative path' do
        let(:manifest) { BASIC_MANIFEST.sub('class testing(', 'class relative(') }
        let(:data) do
          path = Pathname.new(ManifestFileFactory.build(manifest).path).relative_path_from(Pathname.new(Dir.pwd))
          PuppetStringsModuleParser.parse(path.to_s)
        end
        let(:parameters) { data[:parameters] }
        specify { parameters.must_include 'version' }
      end
    end
  end
end
