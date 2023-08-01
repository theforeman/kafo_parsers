require 'test_helper'
require 'kafo_parsers/param_doc_parser'

module KafoParsers
  describe ParamDocParser do
    let(:parser) { ParamDocParser.new(:example, doc) }

    describe "one line" do
      let(:doc) { "example parameter documentation" }
      specify { _(parser.doc).must_equal ["example parameter documentation"] }
      specify { _(parser.condition).must_be_nil }
      specify { _(parser.group).must_be_nil }
      specify { _(parser.type).must_be_nil }
    end

    describe "multi-line" do
      let(:doc) { ["example parameter", "     documentation"] }
      specify { _(parser.doc).must_equal ["example parameter", "documentation"] }
      specify { _(parser.condition).must_be_nil }
      specify { _(parser.group).must_be_nil }
      specify { _(parser.type).must_be_nil }
    end

    describe "multi-line with group" do
      let(:doc) { ["example parameter", "     documentation", "    group: Advanced parameters"] }
      specify { _(parser.doc).must_equal ["example parameter", "documentation"] }
      specify { _(parser.condition).must_be_nil }
      specify { _(parser.group).must_equal ["Advanced parameters"] }
      specify { _(parser.type).must_be_nil }
    end

    describe "multi-line with nested group" do
      let(:doc) { ["example parameter", "     documentation", "    group: Advanced parameters,MySQL"] }
      specify { _(parser.doc).must_equal ["example parameter", "documentation"] }
      specify { _(parser.condition).must_be_nil }
      specify { _(parser.group).must_equal ["Advanced parameters", "MySQL"] }
      specify { _(parser.type).must_be_nil }
    end

    describe "multi-line with type" do
      let(:doc) { ["example parameter", "     documentation", "    type: Optional[Hash[String, Array[Integer]]]"] }
      specify { _(parser.doc).must_equal ["example parameter", "documentation"] }
      specify { _(parser.condition).must_be_nil }
      specify { _(parser.group).must_be_nil }
      specify { _(parser.type).must_equal "Optional[Hash[String, Array[Integer]]]" }
    end

    describe "multi-line with condition" do
      let(:doc) { ["example parameter", "     documentation", "    condition: $db_type == 'sqlite'"] }
      specify { _(parser.doc).must_equal ["example parameter", "documentation"] }
      specify { _(parser.condition).must_equal "$db_type == 'sqlite'" }
      specify { _(parser.group).must_be_nil }
      specify { _(parser.type).must_be_nil }
    end
  end
end
