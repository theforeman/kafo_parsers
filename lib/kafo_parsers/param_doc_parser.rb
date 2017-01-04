require 'kafo_parsers/exceptions'

module KafoParsers
  class ParamDocParser
    ATTRIBUTE_LINE   = /^(condition|group|type)\s*:\s*(.*)/

    def initialize(param, text)
      @param = param
      @metadata = {}
      parse_paragraph([text].flatten)
    end

    attr_reader :param, :doc
    [:condition, :group, :type].each do |attr|
      define_method(attr) do
        @metadata[attr]
      end
    end

    private

    def parse_paragraph(text)
      text_parts       = text.map(&:strip)
      attributes, docs = text_parts.partition { |line| line =~ ATTRIBUTE_LINE }
      parse_attributes(attributes)
      @doc = docs
    end

    def parse_attributes(attributes)
      attributes.each do |attribute|
        data        = attribute.match(ATTRIBUTE_LINE)
        name, value = data[1], data[2]
        raise KafoParsers::DocParseError, "Two or more #{name} lines defined for #{param}" if @metadata.key?(name)
        @metadata[name.to_sym] = value
      end

      if @metadata.key?(:group)
        @metadata[:group] = @metadata[:group].split(/\s*,\s*/)
      end
    end
  end
end
