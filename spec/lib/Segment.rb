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
    attr_reader :children
    
    # NAME: new
    # DESC: creates a new HL7::Segment object from its original text
    # ARGS: 3
    #  segment_text [String] - the text of the segment, with or without its Type field
    # RETURNS:
    #  [HL7::Segment] newly-created Segment
    # EXAMPLE:
    #  HL7::Segment.new( "PID|a|b|c" ) => new Segment with text "a|b|c" and fields ["a","b","c"]
    def initialize(separators, type, *segment_text_by_line)
      raise_error_if(segment_text_by_line.empty?)
      @lines = segment_text_by_line   
      @separators = separators
      @children = []
      @child_class = HL7.typed_segment(type)
      add_typed_segments
    end

    # NAME: to_s
    # DESC: returns the segment as a String object
    # ARGS: none 
    # RETURNS:
    #  [String] the segment in textual form, with the type field added back in
    # EXAMPLE:
    #  segment.to_s => "TYPE|a|b|c"    
    def to_s
      @lines * HL7::SEG_DELIM
    end
    
    # NAME: each
    # DESC: performs actions for each object, self + all children
    # ARGS: 1
    #  [code block] - the code to execute on each line
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  1-line segment: segment.each{ |s| print s + ' & ' } => a & b & c
    #  2-line segment: segment.each{ |s| print s + ' & ' } => [a,b,c] & [a2,b2,c2] 
    def each(&block)
      @children.each{ |child| yield(child) }
    end
    
    # NAME: each_line
    # DESC: performs actions with the fields in each line of the segment
    #       despite the name, manipulates @fields_by_line and not @lines
    # ARGS: 1
    #  [code block] - the code to execute on each line
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  segment.each_line{ |l| print l.join("|") + ' & ' } => a|b|c & a2|b2|c2 & a3|b3|c3 
    def each_line
      @fields_by_line.each{ |row| yield( row ) }
    end

    # NAME: each_field
    # DESC: performs actions for each field of the first line of the segment
    # ARGS: 1
    #  [code block] - the code to execute on each line
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  segment.each_field{ |f| print f.to_s + ' & ' } => a & b & c     
    def each_field
      @fields.each{ |f_obj| yield(f_obj) }
    end

    # NAME: []
    # DESC: returns field at given index (in this line only!)
    # ARGS: 1
    #  index [Integer/Symbol/String] - the index or name of the field we want -- count starts at 1
    # RETURNS:
    #  [String] the value of the field
    # EXAMPLE:
    #  segment[2] => "b"
    #  segment[:beta] => "b"  
    # ALIASES: field()  
    def [](which)
      field(which).to_s
    end
    
    # NAME: field
    # DESC: returns field at given index (in this line only!)
    # ARGS: 1
    #  index [Integer/Symbol/String] - the index or name of the field we want -- count starts at 1
    # RETURNS:
    #  [Field] the actual field object
    # EXAMPLE:
    #  segment.field(2) => "b"
    #  segment.field(:beta) => "b" 
    def field( which )
      i = field_index(which)
      i == @@no_index_val ? nil : @fields[i]
    end
    
    # NAME: all_fields
    # DESC: returns array of fields at given index (in this line and all children!)
    # ARGS: 1
    #  index [Integer/Symbol/String] - the index or name of the field we want -- count starts at 1
    # RETURNS:
    #  [Array] the value of the field for each line
    #      ==>  if there is only one line of this segment's type, returns field() IN AN ARRAY
    # EXAMPLE:
    #  segment.all_fields(2) => [ "b", "b2", "b3" ]
    #  segment.all_fields(:beta) => [ "b", "b2", "b3" ] 
    def all_fields( which )
      i = field_index(which)

      all = []
      @fields_by_line.each{ |row| all << row[i] } if i != @@no_index_val
      all
    end
    
    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # MATCHES METHODS: Array#size, Array#each, Array#[], Array#first, Array#last
    #                  calls matched method on @children; otherwise, throws exception
    # EXAMPLE:
    #  message.size => 5
    #  message.balloon => throws NoMethodError    
    def method_missing( sym, *args, &block )
      methods_it_responds_to = [:first, :last, :size, :each, :[]]
      if methods_it_responds_to.include?(sym) then @children.send(sym, *args)
      else super
      end
    end

    # NAME: view
    # DESC: displays the fields, for each line, clearly enumerated
    # ARGS: none
    # RETURNS: nothing; writes to stdout
    # EXAMPLE:
    #  1-line segment: segment.view => 1:a, 2:b, 3:c
    #  2-line segment: segment.view => 1:a, 2:b, 3:c
    #                                  1:a2, 2:b2, 3:c2
    def view
    end
    
    private

    # called by initialize
    # breaks the text into its fields
    # updates @fields
    def break_into_fields
      @lines.each do |line|
        fields = line.split(@separators[:field])
        @fields = fields.map { |field_text| Field.new(field_text, @separators[:comp]) }
      end
    end

    # called by initialize
    # breaks each line of text into another Segment, but with the correct type
    # updates @children
    def add_typed_segments
      @lines.each do |line|
        text = remove_name_field(line)
        @children << @child_class.new(@separators.clone, text)
      end
    end
    
    # called by add_typed_segments
    def remove_name_field(line)
      return line unless line[HL7::SEGMENT]
      _, nameless_line = line.split(HL7::SEGMENT)
      nameless_line
    end

    def raise_error_if(condition)
      raise HL7::InputError, "HL7::Segment requires valid text" if condition
    end
    
  end
end