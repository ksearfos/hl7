#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::Segment
#
# DESC: Defines a segment in a HL7 message
#       A segment is any number of lines of text, each headed with the same type (3 capital letters, e.g. 'PID')
#         and separated into fields with pipes (|)
#       The Segment class keeps track of the full text of the segment minus its type and any type-specific criteria
#         such as which field types are contained. Those vary from type-to-type, and yet are consistent for all
#         instances of that type, and as such have been given their own subclasses (or more accurately, metaclasses)
#         which are defined as-needed at runtime.  To see what is added to each typed segment, see SegmentEigenclass.rb.
#       A message may contain more than one line of the same segment type--it is not uncommon, for instance, to see 20+ OBX lines
#       This module treats all 20+ lines as lines in a single segment of the message, handled by a single OBX < Segment object
#       For example, if there are 4 OBX segments in one message: MESSAGE => OBX => line1, line2, line3, line4
#       A Segment can be treated as text or as a collection of fields, depending on what is needed
#
# EXAMPLE: PID => "|12345||SMITH^JOHN||19631017|M|||" / [,"12345",,"SMITH^JOHN",,"19631017","M",,]
#
# READ-ONLY INSTANCE VARIABLES:
#    @original_text [String]: stores all lines of this segment as they were originally, e.g. "PID|12345||SMITH^JOHN||19631017|M|||"
#    @fields [Array]: stores each field (in each line) as a HL7::Field object
#    @lines [Array]: stores the original text for each line containing a segment of this type, minus the type itself
#             ====>  for example, for 2 OBX segments: @lines = [ "1|TX|My favorite number is:", "2|NM|42" ]
#
# CLASS METHODS: 
#    self.subclasses: returns Array of all instantiated subclasses of Segment
#    self.is_eigenclass?: returns false if calling class is Segment; true if it's one of the typed derivatives like PID
#             ====>  TypedSegment.rb defines these
#
# INSTANCE METHODS:
#    new(segment_text): creates new Segment object based off of given text
#    to_s: returns String form of Segment (including child segments)
#    [](which): returns value of field with given name or at given index, for the first line only - count starts at 1
#    field(which): returns Field object with given name or at given index, for the first line only - count starts at 1
#    all_fields(which): as [], but for all child segments
#    each(&block): loops through each child segment, executing code on the Field objects
#    method_missing: tries to reference a field with the name of the method, if segment has a type
#                    calls certain Array methods on @children
#                    otherwise throws exception
#    view_fields: prints fields to stdout in readable form, headed by field index
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/12/14 11:12 AM
#
# LAST TESTED: 3/12/14
#
#------------------------------------------

module HL7
  class Segment    
    def initialize(split_segment_text, separators)
      raise_error_if(!split_segment_text.is_a?(SplitText))
      raise_error_if(split_segment_text.value.empty?)
      
      @text = split_segment_text.value   # [[type, line1], [type, line2], ...]
      @separators = separators
      get_lines_from_text                # sets @lines: [line1, line2, ...]
      separate_lines_into_fields         # sets @fields: [[field1, field2, ...], [field1, field2, ...], ...]
      add_type_values(@text[0][0])
    end
   
    def to_s
      @lines * HL7::SEGMENT_DELIMITER
    end
    
    # DESC: performs actions for each field
    def each(&block)
      @fields.flatten.each{ |field| yield(field) }
    end
    
    # DESC: performs actions for each line (as an array of fields) 
    def each_line
      @fields.each{ |row| yield( row ) }
    end
 
    # returns value of field, as string
    def [](index)
      field(index).to_s
    end
    
    # returns value of field, as Field
    def field( which )
      index = field_index(which)
      @fields[0][index]
    end
    
    # DESC: returns array of fields at given index (in this line and all children!)
    def all_fields(index)
      index = field_index(which)
      @fields.map{ |row| row[index] }
    end

    def show
      @text.each { |type, line_text| puts "#{type}: #{line_text}" }
    end
    
    private

    # called by initialize
    def get_lines_from_text
      @lines = @text.transpose.last
    end
    
    # called by initialize
    def separate_lines_into_fields
      @fields = @lines.map { |line| line.split(@separators[:field]) }
      @fields.map! { |field_text_array| make_fields_array(field_text_array) }
    end

    # called by separate_lines_into_fields
    def make_fields_array(text_array)
       text_array.map { |field_text| HL7::Field.new(field_text, @separators.clone) }  
    end
    
    def raise_error_if(condition)
      raise HL7::InputError, "HL7::Segment requires valid text" if condition
    end
    
  end
end