#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::Segment child classes
#
# DESC: Defines a segment in a HL7 message. Specifically adds dynamic functionality for Segment eigenclasses for different
#         types of segments, e.g. a PID eigenclass or a MSH eigenclass.
#       A segment is any number of lines of text, each headed with the same type (3 capital letters, e.g. 'PID') and
#         separated into fields with pipes (|). An eigenclass will add a type and a map of field names to the fields' indices.
#       Since the fields vary by segment type, and we want every segment of the same type to have the same values available,
#         they should be class-level variables. I could create a static class for each segment type, but that is incredibly
#         annoying and requires maintenance--not to mention it gives every Segment the same fields, regardless of type.
#       Instead, we will have 1 eigenclass for each segment type in the message we are reading, created at runtime.
#
# EXAMPLE: new_typed_segment(:PID) => PID class inheriting from HL7::Segment
#          PID.new(text) => object with @type = :PID, @field_index_maps = HL7::PID_FIELDS, class = PID, superclass = Segment
#
# READ-WRITE EIGENCLASS VARIABLES:
#    @type [Symbol] - the segment type
#    @field_index_maps [Hash] - map of field name to its index
#    ====>  Note that these act as class variables to instances of any eigenclasses, and do not exist for instances of Segment
#
# EIGENCLASS METHODS: 
#    self.add(field,index): addes new fieldname-index pair to @field_index_maps
#
# SEGMENT CLASS METHODS:
#    self.subclasses: returns Array of all instantiated subclasses of Segment
#    self.is_eigenclass?: returns false if calling class is Segment; true if it's one of the typed derivatives like PID
#
# SEGMENT INSTANCE METHODS:
#    type: returns value of @type for this object - will be nil if object instantiates Segment directly
#    field_index_maps: returns value of @field_index_maps for this object - will be nil of object instantiates Segment directly
#
# MODULE METHODS:
#    typed_segment(type): returns segment child class called TYPE; creates one first, if necessary
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/12/14 12:53 PM
#
# LAST TESTED: 3/12/14
#
#------------------------------------------

module HL7
  module SegmentTyping
    
    def add_type_values(type)
      @type = type
      @field_index_maps = HL7.const_get("#{@type.upcase}_FIELDS")
    end
  
    def type
      @type
    end

    def field_index_maps
      @field_index_maps
    end

    private
    
    def field_index(which_field)
      index = integerize_field_index(which_field)
            
      if index.is_a?(Integer)
        which_field < 0 ? which_field : which_field - 1  # count starts at 1; array index starts at 0
      else
        raise NoIndexError "Cannot find field #{index} of type #{index.class}"
      end
    end
    
    # called by field_index
    def integerize_field_index(description)
      return description unless is_field_text?(description)     
      index = index_for_description(description)
      index ? index - 1 : description
    end
    
    # called by integerize_field_index
    def is_field_text?(description)
      description.is_a?(String) || description.is_a?(Symbol)
    end
    
    # called by integerize_field_index
    def index_for_description(description)
      field_symbol = description.downcase.to_sym
      field_index_maps[field_symbol]
    end
  end        
end