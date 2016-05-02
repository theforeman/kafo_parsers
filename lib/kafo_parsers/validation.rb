module KafoParsers
  class Validation
    attr_reader :name, :arguments

    def initialize(name, arguments)
      @name = name
      @arguments = arguments
    end
  end
end
