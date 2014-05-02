require 'playground/formatting'

module HL7
  
  class Field
    attr_reader :value, :components
    
    def initialize(text, component_separator = '^')
      verify_input(text)
      @value = text
      @component_separator = component_separator
      @components = split_into_components
    end
    
    def [](index)
      raise "Cannot access components at negative indices" if index < 0
      @components[index-1]
    end
    
    def return_as(type)
      HL7.send("make_#{type}", @value)
    end
    
    def empty?
      @value.empty?
    end
    
    def size
      @components.size
    end
  
    private
    
    def split_into_components
      @components = @value.split(@component_separator)
    end
    
    def verify_input(argument)
      raise "HL7::Field requires a String but was given #{argument}, a #{argument.class}" unless argument.is_a? String
    end
  end  
end