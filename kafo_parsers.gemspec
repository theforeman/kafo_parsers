# coding: utf-8
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'kafo_parsers', 'version')

Gem::Specification.new do |spec|
  spec.name          = "kafo_parsers"
  spec.version       = KafoParsers::VERSION
  spec.authors       = ["Marek Hulan"]
  spec.email         = ["mhulan@redhat.com"]
  spec.summary       = %q{Puppet module parsers}
  spec.description   = %q{This gem can parse values, validations, documentation, types, groups and conditions of parameters from your puppet modules}
  spec.homepage      = "https://github.com/theforeman/kafo_parsers"
  spec.license       = "GPL-3.0+"

  spec.files         = `git ls-files`.split($/)
  spec.files         = Dir['lib/**/*'] + ['LICENSE.txt', 'Rakefile', 'README.md']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7', '< 4'

  spec.add_development_dependency "bundler", ">= 1.5", "< 3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "ci_reporter_minitest", "~> 1.0"

  # puppet manifests parsing
  spec.add_dependency "rdoc", ">= 3.9.0", "< 7"
  spec.add_dependency "json", "~> 2.0"
end
