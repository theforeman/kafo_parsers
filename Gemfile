source 'https://rubygems.org'

# Specify your gem's dependencies in kafo_parsers.gemspec
gemspec

if RUBY_VERSION < '2.1'
  # Technically not needed, but avoids issues with bundler versions
  gem 'rdoc', '< 5.0.0'
elsif RUBY_VERSION < '2.2'
  gem 'rdoc', '< 6.0.0'
end

if ENV['PUPPET_VERSION']
  gem 'puppet', "~> #{ENV['PUPPET_VERSION']}"
else
  gem 'puppet', '>= 4.5.0', '< 8.0.0'
end

gem 'puppet-strings', '>= 1.2.0', '< 3'
