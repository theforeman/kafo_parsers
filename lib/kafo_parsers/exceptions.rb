# encoding: UTF-8
module KafoParsers
  class DocParseError < StandardError
  end

  class ModuleName < StandardError
  end

  class ParserNotAvailable < StandardError
    def initialize(wrapped)
      if wrapped.is_a?(Exception)
        @wrapped = wrapped
      else
        @message = wrapped
      end
    end

    def message
      @message || @wrapped.message
    end
  end
  
  class ParseError < StandardError
  end
end
