# KafoParsers

This gem can parse values, validations, documentation, types, groups and
conditions of parameters from your puppet modules. Only thing you have
to do is provide a path to manifest file you want to be parsed.

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
require 'kafo_parsers/kafo_module_parser'
hash = KafoParsers::KafoModuleParser.parse('/puppet/module/manifests/init.pp')
p hash
```

# License

This project is licensed under the GPLv3+.
