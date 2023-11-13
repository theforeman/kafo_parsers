# encoding: UTF-8
require 'rdoc'
require 'rdoc/markup' # required for RDoc < 0.9.5
require 'rdoc/markup/parser' # required for RDoc < 0.9.5
require 'kafo_parsers/exceptions'
require 'kafo_parsers/param_doc_parser'

module KafoParsers
  class DocParser
    ATTRIBUTE_LINE   = /^(condition)\s*:\s*(.*)/
    HEADER_CONDITION = /\A(.+)\s*condition:\s*(.+)\Z/

    def initialize(text)
      @text           = text
      @nesting_buffer = []
      @docs           = {}
      @groups         = {}
      @conditions     = {}
      @rdoc           = rdoc_parser.parse(@text)
    end

    attr_reader :docs, :groups, :conditions

    # items is array of RDoc::Markup::* on one level
    def parse(items = @rdoc.parts)
      items.each do |item|
        if item.is_a?(RDoc::Markup::Heading)
          parse_header(item)
        elsif item.is_a?(RDoc::Markup::List) && item.respond_to?(:items)
          parse(item.items)
        elsif item.is_a?(RDoc::Markup::ListItem)
          parse_paragraph(item)
        end
      end
      self
    end

    private

    def parse_paragraph(para)
      # Skip rdoc paras that aren't paragraphs
      return unless (para.parts.to_s.scan("RDoc::Markup::Paragraph") == ["RDoc::Markup::Paragraph"])
      # RDoc (>= 4) makes label an array
      label = para.label.is_a?(Array) ? para.label.first : para.label
      # Documentation must be a list - if there's no label then skip
      return if label.nil?
      key              = label.gsub(/[^A-Za-z0-9_-]/, '')
      @groups[key]     = current_groups
      text_parts       = para.parts.first.parts

      param_parser = ParamDocParser.new(key, text_parts)
      @docs[key] = param_parser.doc
      parse_attributes(key, param_parser)
    end

    def parse_attributes(parameter, parser)
      condition              = [current_condition, parser.condition].compact.join(' && ')
      @conditions[parameter] = condition.empty? ? nil : condition
    end

    def parse_header(heading)
      if heading.level > current_level
        @nesting_buffer.push nesting(heading)
      elsif heading.level == current_level
        @nesting_buffer.pop
        @nesting_buffer.push nesting(heading)
      else
        while current_level >= heading.level do
          @nesting_buffer.pop
        end
        @nesting_buffer.push nesting(heading)
      end
    end

    def nesting(heading)
      if heading.text =~ HEADER_CONDITION
        text, condition = $1, $2
      else
        text, condition = heading.text, nil
      end
      Nesting.new(text.strip, heading.level, condition)
    end

    def current_groups
      @nesting_buffer.map(&:name)
    end

    def current_level
      current_nesting.nil? ? 0 : current_nesting.level
    end

    def current_condition
      condition = @nesting_buffer.map(&:condition).select { |c| !c.nil? }.join(' && ')
      condition.empty? ? nil : condition
    end

    def current_nesting
      @nesting_buffer.last
    end

    def rdoc_parser
      if RDoc::Markup.respond_to?(:parse)
        RDoc::Markup
      else # RDoc < 3.10.0
        RDoc::Markup::Parser
      end
    end

    class Nesting < Struct.new(:name, :level, :condition);
    end
  end
end
