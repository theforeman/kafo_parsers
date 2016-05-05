source 'https://rubygems.org'

# Specify your gem's dependencies in kafo_parsers.gemspec
gemspec

puppet_version = ENV['PUPPET_VERSION']
puppet_spec = puppet_version ? "~> #{puppet_version}" : '< 5.0.0'
gem 'puppet', puppet_spec

if puppet_version.nil? || (puppet_version >= '3.7' && RUBY_VERSION >= '1.9')
  gem 'puppet-strings'
end
