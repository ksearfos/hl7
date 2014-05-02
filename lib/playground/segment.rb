module HL7
  class Segment
    attr_reader :value
    
    def initialize(text)
      @value = text
    end
  end
end