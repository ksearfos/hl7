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
# CLASS VARIABLES: none; uses HL7::SEG_DELIM
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
    attr_reader :segments, :lines, :id, :type

    # NAME: new
    # DESC: creates a new HL7::Message object from its original text
    # ARGS: 1
    #  message_text [String] - the text of the message
    def initialize(message_text)
      raise_error_if(message_text.empty?)
      
      @original_text = message_text
      @lines = []            # the list of segments, in order
      @segments = {}         # map of segments by type => { :SEG_TYPE => Segment object }
      @separators = {}       # the separators used by this HL7 message
      @type = :""
      
      break_into_segments    # updates @lines, @segments @separators
      set_message_type       # updates @type
      @id = header.message_control_id
    end  

    # NAME: to_s
    # DESC: returns the message as a String object
    # ARGS: none 
    # RETURNS:
    #  [String] the original text of the message   
    def to_s
      @original_text
    end

    # NAME: each_segment
    # DESC: performs actions for each Segment object
    # ARGS: 1
    #  [code block] - the code to execute on each line
    # RETURNS: depends on the code block
    # EXAMPLE:
    #  message.each_segment { |s| print s.class + ' & ' } => MSH & PID & PV1 & ...   
    def each_segment
      @segments.each_value{ |segment_obj| yield(segment_obj) }  
    end

    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # MATCHES METHODS: Hash#size, Hash#each, Hash#[]
    #                  calls matched method on @records; otherwise, throws exception
    # EXAMPLE:
    #  message.size => 5
    #  message.balloon => throws NoMethodError    
    def method_missing( sym, *args, &block )
      methods_it_responds_to = [:size, :each, :[]]
      if methods_it_responds_to.include?(sym) then @segments.send(sym, *args)
      else super
      end
    end

    # NAME: header
    # DESC: returns the message header (the MSH segment) as a string
    # ARGS: none
    # RETURNS:
    #  [String] the text of the header
    # EXAMPLE:
    #  message.header => "MSH|^~\&|HLAB|RMH|||20140128041144||ORU^R01|201401280411444405|T|2.4" 
    def header
      @segments[:MSH]
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
      @segments.each{ |type, object| 
        name = "#{type.to_s}: "
        print name, object.lines * "\n#{name}"
        print "\n" 
      }
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
      i = @lines.index(segment)
      @lines[i-1]
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
      i = @lines.index(segment)
      @lines[i+1]
    end
    
    private
    
    # called by initialize
    # breaks the text into segments by name
    # updates @lines, @segments, @separators
    def break_into_segments    
      lines = @original_text.split(HL7::SEG_DELIM)
      parse_out_separators(lines.first)    # sets @separators; first line is always the header 
      find_segment_types(lines)            # sets @lines
      parse_out_segments_from_text(lines)  # sets @segments
    end
    
    # called by break_into_segments
    # identifies all segments found in the text by type
    # updates @lines
    def find_segment_types(all_lines)
      all_lines.each do |line|
        raise_error_if(line !~ HL7::SEGMENT)
        @lines << line[HL7::SEGMENT].chop.to_sym   # remember, it ends with the field delimiter (|)
      end    
      @lines.uniq!
    end
    
    # called by break_into_segments
    # updates @separators
    def parse_out_separators(header_text)    
      i = header_text.index("MSH") + 3       # index of the first character after 'MSH'
      @separators = { field: header_text[i],
                      comp: header_text[i+1],
                      subcomp: header_text[i+2],
                      subsub: header_text[i+3], 
                      sub_subsub: header_text[i+4]
                    } 
    end

    # called by break_into_segments
    def parse_out_segments_from_text(all_lines)
      @lines.each do |segment_type|
        segment_text = all_lines_in_segment(segment_type, all_lines) 
        add_segment(segment_type, segment_text)  
      end
    end

    # called by parse_out_segments_from_text
    def all_lines_in_segment(segment_type, all_lines)
      segment_lines = all_lines.clone
      segment_lines.keep_if { |line| line.include?(segment_type.to_s) } 
      raise_error_if(segment_lines.empty?)
      segment_lines
    end
    
    # called by parse_out_segments_from_text    
    # type is a string, body is an array of strings
    def add_segment(type, lines)
      @segments[type] = Segment.new(@separators.clone, type, *lines)   # initialize segment type, if this is the first time we've encountered it 
    end

    def set_message_type
      type = header[2].to_s
      if type =~ /LAB/ then @type = :lab
      elsif type =~ /RAD/ then @type = :rad
      else @type = :enc
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