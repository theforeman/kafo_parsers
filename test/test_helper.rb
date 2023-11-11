require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/mock'
require 'pathname'

require 'manifest_file_factory'

BASIC_MANIFEST = <<EOS
# This manifests is used for testing
#
# It has no value except of covering use cases that we must test.
#
# === Parameters
#
# $required::        something without a default value
# $version::         some version number
# $sub_version::     some sub version string
# $documented::      something that is documented but not used
# $undef::           default is undef
# $multiline::       param with multiline
#                    documentation
#                    consisting of 3 lines
# $multivalue::      list of users
# $mapped::          some mapping
# === Advanced parameters
#
# $debug::           we have advanced parameter, yay!
# $db_type::         can be mysql or sqlite
#
# ==== MySQL         condition: $db_type == 'mysql'
#
# $remote::          socket or remote connection
# $server::          hostname
#                    condition: $remote
# $username::        username
# $password::        db password
#                    condition:$username != 'root'
#
# ==== Sqlite        condition: $db_type == 'sqlite'
#
# $file::            filename
#
# === Extra parameters
#
# $log_level::       we can get up in levels
# $variable::        set in a params class
# $m_i_a::
#
class testing(
  $required,
  $version = '1.0',
  $sub_version = "beta",
  String $undocumented = 'does not have documentation',
  $undef = undef,
  $multiline = undef,
  Array[String] $multivalue = ['x', 'y'],
  Hash[String, Optional[String]] $mapped = {'apples' => 'oranges', unquoted => undef},
  Boolean $debug = true,
  $db_type = 'mysql',
  Boolean $remote = true,
  $server = 'mysql.example.com',
  $username = 'root',
  $password = 'toor',
  $file = undef,
  $variable = $::testing::params::variable,
  $m_i_a = 'test') {

  if $version == '1.0' {
    # this must be ignored since we can't evaluate conditions
    validate_bool($undef)
  }

  package {"testing":
    ensure => present
  }
}
EOS

DEFINITION_MANIFEST = BASIC_MANIFEST.sub('class testing(', 'define testing2(')

BASIC_YARD_MANIFEST = <<EOS
# This manifests is used for testing
#
# It has no value except of covering use cases that we must test.
#
# @param required            something without a default value
# @param version             some version number
# @param sub_version         some sub version string
# @param documented          something that is documented but not used
# @param undef               default is undef
# @param multiline           param with multiline
#                            documentation
#                            consisting of 3 lines
# @param multivalue          list of users
# @param mapped              some mapping
# @param m_i_a
#
# @param debug               we have advanced parameter, yay!
#                            group:Advanced parameters
# @param db_type             can be mysql or sqlite
#                            group:Advanced parameters
#
# @param remote              socket or remote connection
#                            group: Advanced parameters, MySQL
# @param server              hostname
#                            condition: $remote
#                            group: Advanced parameters, MySQL
# @param username            username
#                            group: Advanced parameters, MySQL
# @param password [password] condition:$username != 'root'
#                            group: Advanced parameters, MySQL
#
# @param file                filename
#                            group: Advanced parameters, Sqlite
#
# @param log_level           we can get up in levels
#                            group: Extra parameters
#
class testing(
  String $required,
  Any $version = '1.0',
  String $sub_version = "beta",
  String $undocumented = 'does not have documentation',
  Optional[Integer] $undef = undef,
  Optional[String] $multiline = undef,
  Array[String] $multivalue = ['x', 'y'],
  Hash[String, Optional[String]] $mapped = {'apples' => 'oranges', unquoted => undef},
  $debug = true,
  Enum['mysql', 'sqlite'] $db_type = 'mysql',
  Boolean $remote = true,
  String $server = 'mysql.example.com',
  String $username = 'root',
  $password = 'toor',
  Optional[String] $file = undef,
  String $variable = $::testing::params::variable,
  String $m_i_a = 'test') {

  if $version == '1.0' {
    # this must be ignored since we can't evaluate conditions
    validate_bool($undef)
  }

  package {"testing":
    ensure => present
  }
}
EOS

class Minitest::Spec
  before do

  end
end
