# encoding: UTF-8
module KafoParsers
  class DocParseError < StandardError
  end

  class ModuleName < StandardError
  end

  class ParserNotAvailable < StandardError
    def initialize(wrapped)
      @wrapped = wrapped
    end

    def message
      @wrapped.message
    end
  end
end
