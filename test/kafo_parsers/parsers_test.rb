require 'test_helper'
require 'kafo_parsers/parsers'

module KafoParsers
  describe Parsers do
    describe ".all" do
      specify { _(Parsers.all).must_be_kind_of Array }
    end

    describe ".find_available" do
      let(:parser1) { PuppetStringsModuleParser }

      specify { Parsers.stub(:all, []) { _(Parsers.find_available).must_be_nil } }

      specify do
        parser1.stub(:available?, true) do
          Parsers.stub(:all, [parser1]) { _(Parsers.find_available).must_equal parser1 }
        end
      end

      specify do
        parser1.stub(:available?, false) do
          Parsers.stub(:all, [parser1]) { _(Parsers.find_available).must_be_nil }
        end
      end

      specify do
        parser1.stub(:available?, Proc.new { raise KafoParsers::ParserNotAvailable.new('N/A') } ) do
          Parsers.stub(:all, [parser1]) { _(Parsers.find_available).must_be_nil }
        end
      end
    end
  end
end
