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
# READ-ONLY INSTANCE VARIABLES: segs lines msg id
#    @original_text [String]: stores entire message text
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
#    to_s: returns String form of Message
#    [](key): returns Segment of given type
#    each(&block): loops through each segment type-object pair, executing given code
#    each_segment(&block): loops through each segment object, executing given code
#    method_missing: tries to call method on @segments (Hash)
#                    then tries to call method on @segments.values (Array)
#                    then tries to call method on @original_text (String)
#                    then gives up and throws exception
#    header: returns the message header, e.g. the MSH segment object
#    view_details: prints summary of important message information, such as message ID and patient name
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
    # RETURNS:
    #  [HL7::Message] newly-created Message
    # EXAMPLE:
    #  HL7::Message.new( "MSH|a|b|c\nPID|a|b|c\nPV1|a|b|c\n" ) => new Message with MSH, PID, and PV1 segments 
    def initialize( message_text )
      @original_text = message_text
      @lines = []            # list of lines by their segment types => [ :MSH, :PID, :PV1, :OBX, :OBX, :OBX ]
      @segments = {}         # { :SEG_TYPE => Segment object }
      @separators = {}
      
      break_into_segments    # sets @lines, @segments

      @id = header.message_control_id
      set_message_type
    end  

    # NAME: to_s
    # DESC: returns the message as a String object
    # ARGS: none 
    # RETURNS:
    #  [String] the message in textual form
    # EXAMPLE:
    #  message.to_s => "MSH|a|b|c\nPID|a|b|c\nPV1|a|b|c\n"      
    def to_s
      @original_text
    end

    # NAME: []
    # DESC: returns Segment of given type
    # ARGS: 1
    #  key [Symbol] - the type of segment, a key in the @segments hash
    # RETURNS:
    #  [Segment] the segment object -- generally actually in object of one of the Segment child classes
    # EXAMPLE:
    #  segment[:PID] => PID object      
    def []( key )
      @segments.has_key?(key) ? @segments[key] : []
    end

    # NAME: each
    # DESC: performs actions for each segment type-object pair
    # ARGS: 1
    #  [code block] - the code to execute on each pair
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  message.each{ |k,v| print k + ":" + v.to_s + " & "} => MSH:a|b|c & PID:a|b|c & PV1:a|b|c   
    def each
      @segments.each_pair{ |seg_type,seg_obj| yield(seg_type,seg_obj) }  
    end

    # NAME: each_segment
    # DESC: performs actions for each segment in the message
    # ARGS: 1
    #  [code block] - the code to execute on each line
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  message.each_segment{ |s| print s[5] + ' & ' } => msh5 & pid5 & pv15   
    def each_segment
      @segments.each_value{ |seg_obj| yield(seg_obj) }  
    end

    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # ARGS: 1+
    #  sym [Symbol] - symbol representing the name of the method called
    #  *args - all arguments passed to the method call
    #  [code block] - optional code block passed to the method call
    # RETURNS: depends on handling
    #     ==>  first checks @segments.values for a matching method
    #     ==>  second checks @segments for a matching method
    #     ==>  third checks @original_text for a matching method
    #     ==>  then gives up and throws an Exception
    # EXAMPLE:
    #  message.shuffle => [ PIDObj, OBXObj, PV1Obj, MSHObj ] (calls @segments.values.shuffle)
    #  message.invert => { MSHobj=>:MSH, PIDObj=>:PID, PV1Obj=:PV1 } (calls @segments.invert)
    #  message.gsub( "*", "\n|^" ) => "MSH*a*b*c*PID*a*b*c*PV1*a*b*c" (calls @original_text.gsub)
    #  message.fake_method => throws NoMethodError    
    def method_missing( sym, *args, &block )
      if Array.method_defined?( sym )
        @segments.values.send( sym, *args )
      elsif Hash.method_defined?( sym )
        @segments.send( sym, *args )
      elsif String.method_defined?( sym )
        @original_text.send( sym, *args )
      else
        super
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

    # NAME: view_details
    # DESC: displays crucial information about the message, clearly labelled
    # ARGS: none
    # RETURNS: nothing; writes to stdout
    # EXAMPLE:
    #  message.view_details => Message ID: 12345
    #                          Sent at: 05/15/2013 11:45 AM
    #                          Patient Name: John W Smith
    #                          Account #: 123456789
    #                          Visit Number: 12345
    def view_details
      puts "Message ID: " + @id
      puts "Message type: " + @type.to_s.capitalize
      puts "Sent at: " + header.date_time.as_datetime
      puts "Patient Name: " + @segments[:PID].patient_name
      puts "Account #: " + @segments[:PID].account_number.first
      
      if @type != :adt
        procedure = @segments[:OBR].procedure_id
        time = @segments[:OBR][7].as_datetime
        puts "Procedure: " + procedure
        puts "Collected at: " + time
      else
        puts "Visit Number: " + @segments[:PV1].visit_number
      end
    end

    # NAME: details
    # DESC: compiles crucial information about the message, clearly labelled
    # ARGS: 0+
    #  all [Symbol] - the keys of the details to return - will return all of them by default
    #            ==>  options are: :ID, :TYPE, :DATE, :PT_NAME, :PT_ACCT, :PROC_NAME, :PROC_DATE, :VISIT
    # RETURNS:
    #  [Hash] the requested details
    # EXAMPLE:
    #  message.details(:ID,PT_NAME) => { :ID=>"1234563", :PT_NAME=>"John Smith" } 
    def details( *all )
      all.flatten!
      all.map!{ |key| key = key.upcase.to_sym }
      
      h = {}
      h[:ID] = @id
      h[:TYPE] = @type.to_s.capitalize
      h[:DATE] = header.field(:date_time).as_datetime
      h[:PT_NAME] = @segments[:PID].field(:patient_name).as_name
      h[:PT_ID] = @segments[:PID].field(:mrn).first
      h[:PT_ACCT] = @segments[:PID].field(:account_number).first
      h[:DOB] = @segments[:PID].field(:dob).as_date

      if @type != :adt
        h[:PROC_NAME] = @segments[:OBR].procedure_id
        h[:PROC_DATE] = @segments[:OBR].field(7).as_datetime
      else
        h[:VISIT_DATE] = @segments[:PV1].field(:admit_date_time).as_datetime
      end
      
      return h if all.empty?
      
      h.keep_if{ |key,_| all.include?(key) }
      h
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
      each{ |type,obj| 
        obj.lines.each{ |line| puts type.to_s + ": " + line }
      }
    end
    
    def get_segments
      str = ""
      each{ |type,obj| 
        obj.lines.each{ |line| str << type.to_s + ": " + line + "\n" }
      }
      str
    end

    # NAME: fetch_field
    # DESC: returns array of fields at given index of given segment (in all segments of this type!)
    # ARGS: 1
    #  field [String] - the 3-letter segment type followed by the index of the field, e.g. "pid5"
    # RETURNS:
    #  [Array] the values of the fields for each line of the segment type
    #      ==> this was created for easy handling of segments that have more than one occurrence in a message
    # EXAMPLE:
    #  1-line segment: message.fetch_field("pid1") => [ "12345" ]
    #  2-line segment: message.fetch_field("obx2") => [ "20131223", "20131211" ]
    def fetch_field( field )
      seg = field[0...3]   # first three charcters, the name of the segment - have to do it this way for PV1 etc.
      f = field[3..-1]     # remaining 1-3 characters, the number of the field

      seg_obj = @segments[seg.upcase.to_sym]  # segment expected to be an uppercase symbol
      return [] if seg_obj.nil?
      seg_obj.all_fields( f.to_i )
    end

    # NAME: segment_before
    # DESC: identifies type of segment occurring in the message directly before (all lines of) the specified type
    # ARGS: 1
    #  seg [Symbol] - the segment whose predecessor we seek
    # RETURNS:
    #  [Symbol] the type of the preceeding segment
    # EXAMPLE:
    #  message.segment_before(:PID) => :MSH  
    def segment_before( seg )
      i = @lines.index( seg )
      @lines[i-1]
    end

    # NAME: segment_after
    # DESC: identifies type of segment occurring in the message directly after (all lines of) the specified type
    # ARGS: 1
    #  seg [Symbol] - the segment whose successor we seek
    # RETURNS:
    #  [Symbol] the type of the succeeding segment
    # EXAMPLE:
    #  message.segment_after(:PID) => :PV1    
    def segment_after( seg )
      sinel = @lines.clone.reverse   # yeah, super-clever name, I know
      i = sinel.index( seg )
      sinel[i-1]    # before seg in reverse array == after the seg in original array
    end
    
    private
    
    def break_into_segments    
      lines = @original_text.split( SEG_DELIM )
      parse_out_separators( lines.first )     # first line is always the header    
      lines_by_type = break_apart( lines )    # => { "type" => [ "body1", "body2", "body3", ... ] }
      @lines = lines_by_type.keys.uniq
      
      # now convert text into segment object of specific type (child class) and add to @segments
      @lines.each{ |type| add_segment( type, lines_by_type[type] ) }
    end
    
    def set_message_type
      type = header[2].to_s

      if type.include?( "LAB" )
        @type = :lab
      elsif type.include?( "RAD" )
        @type = :rad
      else
        @type = :adt
      end
    end
    
    def parse_out_separators( header_line )    
      i = header_line.index( "MSH" ) + 3       # index of the first character after 'MSH'
      @separators = { field:header_line[i], comp:header_line[i+1], subcomp:header_line[i+2],
                      subsub:header_line[i+3], sub_subsub:header_line[i+4] } 
    end

    # type is a string, body is an array of strings
    def add_segment( type, body )
      clazz = HL7.typed_segment( type )
      @segments[type] = clazz.new( @separators.clone, *body )  
    end
  
    # returns a hash: { "type" => [ "body1", "body2", "body3", ... ] }
    def break_apart( lines )
      type_to_body = {}
      lines.each{ |line|
        type, *body = line.split( @separators[:field] ) 
        type = :MSH if type.include?( 'MSH' )
        type_to_body[type.to_sym] ||= []    # initialize to empty array if it hasn't been initialized yet
        type_to_body[type.to_sym] << body.join( @separators[:field] ) 
      }    
      type_to_body
    end
  end
end