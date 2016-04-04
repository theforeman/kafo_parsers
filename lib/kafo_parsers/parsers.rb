require 'kafo_parsers/puppet_module_parser.rb'

module KafoParsers
  module Parsers
    def self.all
      [PuppetModuleParser]
    end

    def self.find_available(options = {})
      all.find do |provider|
        begin
          provider.available?
        rescue ParserNotAvailable => e
          options[:logger].debug "Provider #{provider} not available: #{e.message}"
          false
        end
      end
    end
  end
end
