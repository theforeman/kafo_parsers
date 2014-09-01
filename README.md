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

To parse file and see parsed information
```ruby
require 'kafo_parsers/puppet_module_parser'
hash = KafoParsers::PuppetModuleParser.parse('/puppet/module/manifests/init.pp')
p hash
```

# License

This project is licensed under the GPLv3+.
