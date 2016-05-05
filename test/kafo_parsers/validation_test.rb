require 'test_helper'
require 'kafo_parsers/validation'

module KafoParsers
  describe Validation do
    describe "#==" do
      let(:valid1) { Validation.new('valid1', []) }
      let(:valid2) { Validation.new('valid2', [:a, 1]) }
      let(:valid3) { Validation.new('valid2', [:a, 2]) }
      let(:valid4) { Validation.new('valid2', [:a, 1]) }

      specify { valid1.==(valid2).must_equal false }
      specify { valid2.==(valid3).must_equal false }
      specify { valid2.==(valid4).must_equal true }
      specify { valid3.==(valid4).must_equal false }
    end
  end
end
