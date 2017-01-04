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

#### PuppetStringsModuleParser

If you use Puppet 4 you prefer PuppetStringsModuleParser which leverages
puppet-strings to parse puppet manifests. This requires puppet-strings 0.99 or
higher and may be installed either as a gem in the same environment, or in a
Puppet AIO installation.

```ruby
require 'kafo_parsers/puppet_strings_module_parser'
hash = KafoParsers::PuppetStringsModuleParser.parse('/puppet/module/manifests/init.pp')
```

Output will be similar to PuppetModuleParser, only validations are not supported,
since they are not parsed by puppet-strings.

## Documentation syntax

### RDoc syntax

Classes and defined types should be prefixed with a comment section with an RDoc
block, containing a description, headings for different parameter groups and
parameters laid out as shown below:

```puppet
# Example class that installs Example
#
# Supports version 1 to 3.
#
# === Parameters::
#
# $foo::  Sets the value of foo in the Example config
#
# === Advanced parameters::
#
# $bar::  Sets the value of bar in the advanced config
```

Parameters may have multi-line descriptions and can have extra attributes
defined on new lines below them. Supports:

```puppet
# $foo::  Sets the value of foo in the Example config
#         condition: $bar == 'use_foo'
#         type: Optional[String]
```

Supports:

* `condition:` an expression to determine if the parameter is used
* `type:` the data type of the parameter

Used by:

* `PuppetModuleParser`
* `PuppetStringsModuleParser` (but deprecated, prefer YARD)

### YARD syntax

Classes and defined types should be prefixed with a comment section in YARD
following the Puppet Strings documentation standard, as shown below:

```puppet
# Example class that installs Example
#
# Supports version 1 to 3.
#
# @param foo Sets the value of foo in the Example config
# @param bar Sets the value of bar in the advanced config
#            group: Advanced parameters
```

Parameters may have multi-line descriptions and can have extra attributes
defined on new lines below them. Supports:

```puppet
# @param foo Sets the value of foo in the Example config
#            condition: $bar == 'use_foo'
```

Supports:

* `condition:` an expression to determine if the parameter is used
* `group:` comma-separated list of groups, increasing in specificity

Data types are given in the parameter list of the class, or can be given inline
for Puppet 3 compatibility:

```puppet
# @param foo [Integer] Sets the value of foo in the Example config
```

Used by:

* `PuppetStringsModuleParser`

# License

This project is licensed under the GPLv3+.
