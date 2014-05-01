$:.unshift File.dirname(__FILE__)
require 'SplitText'

=begin -------------------------------------------------------------------
  MODULE: HL7
  CLASS: Message
  DESC: Defines a single HL7 message
        A message is all lines of text between a header (MSH segment) and the start of the next header.
          A message comprises multiple lines of text, which can be broken into segments and then fields.
        The message class keeps track of the full text of the message, as well as breaking it into the
          various segments. All Segments of the same type can be accessed by the type, as message[:TYPE]. 
        A message will always contain a single MSH (header) segment, and will generally contain a single
          PID (patient info) segment and a single PV1 (visit info) segment. In addition there will be other
          segment types, some of which may comprise multiple lines in the same message.

  CLASS VARIABLES: none; uses HL7::SEGMENT_DELIMITER
  CLASS METHODS: none; uses HL7.get_separators
  
  INSTANCE VARIABLES:
    @segments [Hash]: stores each segment as a Segment object linked to by type [READ-ONLY]
    @type [Symbol]: either :lab, :rad, or :enc, depending on the value of MSH.2 [READ-ONLY]
  INSTANCE METHODS:
    new(message_text): creates new Message object based off of given text
    to_s: returns String form of Message, which is the text the message was derived from
    each(&block): loops through each segment object, executing given code
    size: returns the number of different segments contained in the message
    [](type): returns the Segment object of the given type
    header: returns the message header, e.g. the MSH segment object
    id: returns the message control ID
    view_segments: displays readable version of the segments
    all_fields(descriptor): returns all values of the segment and field specified, as an Array
    verify_segment_order(segment1, segment2): returns true if segment1 appears after segment2; false otherwise

  CREATED BY: Kelli Searfos
  LAST UPDATED: 4/23 13:23
=end -------------------------------------------------------------------

module HL7
   
  class Message  
    SEGMENT_REGEX = /^([A-Z]{2}[A-Z1]{1})\|/  # regex defining a segment row, matching first three characters
    attr_reader :segments, :type

    # PURPOSE:  creates a new HL7::Message from its original text
    # REQUIRES: message_text [String] - the text of the message
    # RETURNS:  new Message
    def initialize(message_text)
      raise_error_if(message_text.empty?)
      @message_text = message_text            
      extract_separators    # sets @separators
      break_into_segments   # sets @segment_units, @segments
      set_message_type      # sets @type
    end  

    # PURPOSE:  transforms Message into a String
    # REQUIRES: nothing
    # RETURNS:  [String] the base text  
    def to_s
      @message_text
    end

    # PURPOSE:  iterates through each segment, performing given tasks
    # REQUIRES: [code block] - the code to execute for each segment
    # RETURNS:  depends on code block   
    def each
      @segments.each_value{ |segment_obj| yield(segment_obj) }  
    end

    # PURPOSE:  determines the number of different segments in the Message
    # REQUIRES: nothing
    # RETURNS:  [Integer] the number of segments
    # N.B. counts number of different TYPES of segments, NOT the total number of segments/lines
    def size
      @segments.size
    end

    # PURPOSE:  retrieves all segments of the given type
    # REQUIRES: [Symbol] the segment type
    # RETURNS:  [Array] all segments of type    
    def [](segment_type)
      type = segment_type.upcase.to_sym
      @segments[type]
    end 
    
    # PURPOSE:  retrieves the header segment (also known as the MSH segment)
    # REQUIRES: nothing
    # RETURNS:  [Segment] the MSH segment   
    def header
      @segments[:MSH]
    end

    # PURPOSE:  retrieves the message ID
    # REQUIRES: nothing
    # RETURNS:  [String] the message control ID, e.g. MSH.9   
    def id
      header.message_control_id
    end
    
    # PURPOSE:  displays readable version of the segments, headed by the type of the segment
    # REQUIRES: nothing
    # RETURNS:  [String] the text of each segment, labelled and in order
    # EXAMPLE OUTPUT:
    #   MSH: ^~\&|sys|org|||201401281346
    #   PID: abc|123456||SMITH^JOHN^^IV|||19840106
    #   PV1: |O|^^||||12345^Doe^Doug^E^^Dr|12345^Doe^Doug^E^^Dr
    #   OBX: 1|TX|||I like chocolate this much:
    #   OBX: 2|TX|||<-------------------------->                        
    def view_segments
      @segments.each_value { |segment_object| segment_object.show }
    end

    # PURPOSE:  returns values in the given field for each line of the segment
    # REQUIRES: [String] - the 3-letter segment type followed by the field's index, e.g. "pid5"
    # RETURNS:  [Array] the values of the fields for each line of the segment
    def all_fields(field_descriptor)
      type, field = HL7.parse_field_descriptor(field_descriptor)
      segment = @segments[type.upcase.to_sym]
      segment ? segment.all_fields(field) : []
    end

    # PURPOSE:  verifies that the HL7 segments occur in the desired order
    # REQUIRES: [Symbol/String] - the segment type expected to occur first
    #           [Symbol/String] - the segment type expect to occur after the other
    # RETURNS:  true if first_segment precedes later_segment, false otherwise
    def verify_segment_order(first_segment, later_segment)
      segments = segment_types
      segments.index(first_segment.to_s) < segments.index(later_segment.to_s)
    end
    
    private

    # called by initialize
    def extract_separators
      starting_index = @message_text.index("MSH") + 3   # first character after the MSH
      @separators = HL7.get_separators(@message_text, starting_index)
    end
      
    # called by initialize
    def break_into_segments
      @segment_units = []     
      @segments = {}   
      split_by_segment
      segment_types.each { |type| add_new_segment(type) } 
    end
    
    def split_by_segment
      @segment_units = SplitText.new(@message_text.clone, SEGMENT_REGEX)
    end
    
    # called by break_into_segments, segment_before
    def segment_types
      @segment_units.value.transpose[0].uniq
    end
    
    # called by break_into_segments
    def add_new_segment(type)
      segments = @segment_units.value.select { |segment_type, text| segment_type == type }
      @segments[type.to_sym] = Segment.new(segments, @separators.clone)
    end

    # called by initialize
    def set_message_type
      @type = case header.sending_application
        when /LAB$/ then :lab
        when /RAD$/ then :rad
        else :enc
      end
    end  
    
    def raise_error_if(condition)
      raise HL7::InputError, "HL7::Message can only be initialized from valid HL7 text" if condition
    end
    
  end
end