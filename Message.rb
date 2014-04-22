#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::Message
#
# DESC: Defines a single HL7 message
#       A message is all lines of text between a header (MSH segment) and some final segment of varying types.
#         A message comprises multiple lines of text, broken into segments and then fields.
#       The message class keeps track of the full text of the message, as well as breaking it into the various segments
#         as Segment objects. All Segments of the same type can be accessed by the type, as message[:TYPE]. 
#       A single message will always contain a single MSH (header) segment, and will generally contain a single PID
#         (patient info) segment and a single PV1 (visit info) segment. In addition there will be other segment types, often
#         at least one of which will occur multiple times.
#
# EXAMPLE: Message => "MSH|...\nPID|...\nPV1|...\nOBX|1|...\nOBX|2|..." / {:MSH=>Seg1,:PID=>Seg2,:PV1=>Seg3,:OBX=>Seg4}
#
# CLASS VARIABLES: none; uses HL7.separators[:segment]
#
# READ-ONLY INSTANCE VARIABLES:
#    @lines [Array]: stores segment types in the order in which the lines appear in the message, e.g. [:MSH,:PID,:PV1,:OBX,:OBX]
#    @segments [Hash]: stores each segment as a Segment object linked to by type, e.g. { :MSH=>Seg1, :PID=>Seg2, ... }
#               ====>  will actually be objects of one of the Segment child classes
#    @id [String]: stores the message ID, also known as the message control ID or MSH.9
#    @type [Symbol]: either :lab, :rad, or :adt, depending on the value of MSH.2
#
# CLASS METHODS: none
#
# INSTANCE METHODS:
#    new(message_text): creates new Message object based off of given text
#    to_s: returns String form of Message, which is the text the message was derived from
#    each_segment(&block): loops through each segment object, executing given code
#    method_missing: calls certain Hash methods on @segments
#                    otherwise throws exception
#    header: returns the message header, e.g. the MSH segment object
#    details: returns important details for quick summary
#    view_segments: displays readable version of the segments, headed by the type of the segment
#    fetch_field(field): returns the value of the segment and field specified -- fetch_field("abc1") ==> self[:ABC][1]
#                 ====>  always returns array for elegant handling of multi-line segments
#    segment_before(seg): returns name/type of the segment occurring directly before the one specified
#    segment_after(seg): returns the name/type of the segment occurring directly after the one specified
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/13/14 12:00
#
#------------------------------------------

module HL7
   
  class Message  
    attr_reader :segments, :type

    # PURPOSE:  creates a new HL7::Message from its original text
    # REQUIRES: message_text [String] - the text of the message
    # RETURNS:  new Message
    def initialize(message_text)
      raise_error_if(message_text.empty?)
      @message_text = message_text.split(HL7.separators[:segment])
            
      extract_separators    # sets @separators 
      break_into_segments   # sets @segments_as_text, @segments
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
      @segments[segment_type]
    end 

    # PURPOSE:  retrieves a segment of the given type
    # REQUIRES: [Symbol] the segment type
    # RETURNS:  [Segment] the FIRST segment of that type     
    def segment(segment_type)
      @segments[segment_type].first
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
        
    # NAME: details
    # DESC: compiles crucial information about the message, clearly labelled
    # ARGS: 0+
    #  all [Symbol] - the keys of the details to return - will return all of them by default
    #            ==>  options are: :ID, :TYPE, :DATE, :PT_NAME, :PT_ACCT, :PROC_NAME, :PROC_DATE, :VISIT
    # RETURNS:
    #  [Hash] the requested details (all of them by default)
    # EXAMPLE:
    #  message.details(:ID, PT_NAME) => { :ID=>"1234563", :PT_NAME=>"John Smith" } 
    def details(*all)
      info_types = all.empty? ? %w(id type date pt_name pt_acct dob proc_name proc_date visit) : all
      all_details = {}
      info_types.each do |info_type|
        key = info_type.upcase.to_sym     # turn "id" into :ID, for example
        all_details[key] = detail_for(key)
      end
      
      all_details
    end

    # NAME: view_segments
    # DESC: displays readable version of the segments, headed by the type of the segment
    # ARGS: none
    # RETURNS: nothing; writes to stdout
    # EXAMPLE:
    #  message.view_segments => MSH: ^~\&|sys|org|||201401281346
    #                           PID: abc|123456||SMITH^JOHN^^IV|||19840106
    #                           PV1: |O|^^||||12345^Doe^Doug^E^^Dr|12345^Doe^Doug^E^^Dr
    #                           OBX: 1|TX|||I like chocolate this much:
    #                           OBX: 2|TX|||<-------------------------->                        
    def view_segments
      @segments.values.flatten.each { |object| object.show }
    end

    # NAME: fetch_field
    # DESC: returns array of field values at given index of given segment (for all lines)
    # ARGS: 1
    #  field [String] - the 3-letter segment type followed by the index of the field, e.g. "pid5"
    # RETURNS:
    #  [Array] the values of the fields for each line of the segment
    #      ==> this was created for easy handling of segments that have more than one occurrence in a message
    # EXAMPLE:
    #  1-line segment: message.fetch_field("pid1") => [ "12345" ]
    #  2-line segment: message.fetch_field("obx2") => [ "20131223", "20131211" ]
    def fetch_field( field )
      segment_name = field[/\w{3}/]
      segment = @segments[segment_name.upcase.to_sym]    # segment expected to be an uppercase symbol
      segment ? segment.all_fields( f.to_i ) : []
    end

    # NAME: segment_before
    # DESC: identifies type of segment occurring in the message directly before (all lines of) the specified type
    # ARGS: 1
    #  segment [Symbol] - the name of the segment whose predecessor we seek
    # RETURNS:
    #  [Symbol] the name of the preceeding segment
    # EXAMPLE:
    #  message.segment_before(:PID) => :MSH  
    def segment_before(segment)
      i = @segments_in_order.index(segment)
      @segments_in_order[i-1]
    end

    # NAME: segment_after
    # DESC: identifies type of segment occurring in the message directly after (all lines of) the specified type
    # ARGS: 1
    #  segment [Symbol] - the name of the segment whose successor we seek
    # RETURNS:
    #  [Symbol] the name of the successive segment
    # EXAMPLE:
    #  message.segment_after(:PID) => :PV1    
    def segment_after(segment)
      i = @segments_in_order.index(segment)
      @segments_in_order[i+1]
    end
    
    private

    # called by initialize
    def extract_separators
      starting_index = header.index("MSH") + 3   # first character after the MSH
      @separators = HL7.get_separators(header, starting_index)
    end
      
    # called by initialize
    def break_into_segments  
      @segments_as_text = Hash.new([])        
      @message_text.each { |line| add_segment_text(line) }
      add_new_segments
    end
    
    # called by break_into_segments
    def add_segment_text(text)
      type = HL7.segment_type(text)
      @segments_as_text[type] += text
    end
    
    # called by break_into_segments
    def add_new_segment
      @segments = @segments_as_text.map { |_,v| Segment.new(v) }
      segment = Segment.new(text) 
      @segments[segment.type] += segment
    end

    # called by initialize
    def set_message_type
      @type = case header.sending_application
        when /LAB$/ then :lab
        when /RAD$/ then :rad
        else :enc
      end
    end
     
    # called by details
    # this isn't very elegantly implemented, but, hey, it works
    def detail_for(name)
      case name
      when :ID then @id
      when :TYPE then @type.to_s.capitalize
      when :DATE then header.field(:date_time).as_datetime
      when :PT_NAME then @segments[:PID].field(:patient_name).as_name
      when :PT_ID then @segments[:PID].field(:mrn).first
      when :PT_ACCT then @segments[:PID].field(:account_number).first
      when :DOB then @segments[:PID].field(:dob).as_date
      when :PROC_NAME then @segments[:OBR].procedure_id
      when :PROC_DATE then @segments[:OBR].field(7).as_datetime
      when :VISIT_DATE then @segments[:PV1].field(:admit_date_time).as_datetime
      else ""
      end
    end
      
    def raise_error_if(condition)
      raise HL7::InputError, "HL7::Message can only be initialized from valid HL7 text" if condition
    end
    
  end
end