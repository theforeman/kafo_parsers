module KafoParsers
  class Validation
    attr_reader :name, :arguments

    def initialize(name, arguments)
      @name = name
      @arguments = arguments
    end

    def ==(other)
      name == other.name && arguments == other.arguments
    end
  end
end
