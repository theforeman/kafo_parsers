source 'https://rubygems.org'

# Specify your gem's dependencies in kafo_parsers.gemspec
gemspec

gem 'rdoc', '< 6.0.0' if RUBY_VERSION < '2.2'

puppet_version = ENV['PUPPET_VERSION'] || '5.0'
gem 'puppet', "~> #{puppet_version}"
gem 'puppet-strings', '>= 0.99', '< 2'
