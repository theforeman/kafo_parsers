# KafoParsers

This gem can parse values, validations, documentation, types, groups and
conditions of parameters from your puppet modules. Only thing you have
to do is provide a path to manifest file you want to be parsed.

The library is used in [Kafo](https://github.com/theforeman/kafo), which can 
be used to get an idea of what's possible to build on top of this library.

Currently puppet classes and types (definitions) are supported.

## Installation

Add this line to your application's Gemfile:

    gem 'kafo_parsers'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kafo_parsers

## Usage

To parse file using the best available parser, and see parsed information:
```ruby
require 'kafo_parsers/parsers'
parser = KafoParsers::Parsers.find_available or fail('No parser available')
hash = parser.parse('/puppet/module/manifests/init.pp')
p hash
```

`find_available` can take a logger object that responds to `#debug` to log
detailed reasons why each parser isn't available.

```ruby
logger = Logging.logger(STDOUT)
logger.level = :debug
KafoParsers::Parsers.find_available(:logger => logger)
```

To load a specific parser:
```ruby
require 'kafo_parsers/puppet_module_parser'
hash = KafoParsers::PuppetModuleParser.parse('/puppet/module/manifests/init.pp')
```

#### PuppetModuleParser

The standard PuppetModuleParser loads Puppet as a regular library or gem, so it
must be installed in the same Ruby that's running kafo_parsers.

Only Puppet versions 2.6.x, 2.7.x and 3.x are supported.

Add `gem 'puppet', '< 4'` to your application's Gemfile to use this.

# License

This project is licensed under the GPLv3+.
