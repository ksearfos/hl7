#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::FileHandler
#
# DESC: Defines an object to read HL7 message from a file and split it into Message objects. Basically sets the stage
#         for treating the file text as a HL7 message.
#       Performs minor reformatting to insure there are no blank lines, and all line breaks are done with \n and not \r
#       The message handler class takes a filepath where HL7 data is stored, reads from it, and standardizes the format of
#         the text. It then breaks the text into individual records and initializes Message objects from those. It will also
#         keep track of each of those Messages and the value separators used by the message.
#       It is assumed that the file is in a valid text format and uses either the Windows-style line endings (\r and \r\n)
#         or the Unix style (\n). It also assumes the file is UTF-8 encoded.
#
# EXAMPLE: FileHandler => "MSH|...MSH|...MSH|..." / [ Message1, Message2, Message 3 ]
#
# CLASS VARIABLES: none; uses HL7::SEG_DELIM and modifies HL7.separators
#
# READ-ONLY INSTANCE VARIABLES:
#    @file [String]: the name of the file this FileHandler reads from
#    @records [Array]: stores individual records/messages as Message objects
#
# CLASS METHODS: none
#
# INSTANCE METHODS:
#    new(file,limit): creates new FileHandler object and reads in text from file, up to limit records (if specified)
#    to_s: returns String form of FileHandler, which is the text of the file
#    method_missing: calls certain Array methods on @records
#                    otherwise throws exception
#    do_in_increments(&block): runs the code block for each set of records
#    next: gets the next @max_records records and stores them in @records - @records will be empty if there were no more
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 4/9 11:44
#
#------------------------------------------

module HL7
  class FileHandler
    @@eol = "\n"    # the end-of-line character we are using
    attr_reader :records, :file
    
    # NAME: new
    # DESC: creates a new HL7::FileHandler object from a text file
    # ARGS: 1-2
    #  file [String] - complete path to the source file
    #  limit [Integer] - highest number of records to use at one time - 10,000 by default
    # N.B. I've found that storing more than 10,000 Message objects at once usually causes memory allocation errors 
    def initialize( file, limit = 10000 )
      raise HL7::NoFileError, "No such file: #{file}" unless File.exists?(file)
    
      @file = file
      @file_text = ""          # the original text
      @message_text = []       # the text of each message
      @records = []            # all records/messages, as HL7::Message objects
      @max_records = limit     # the largest size @records can have
 
      read_message             # updates @file_text
      break_into_messages      # updates @message_text
      get_records              # updates @records
    end

    # NAME: to_s
    # DESC: returns the message handler as a String object - basically the text of the file
    # ARGS: none 
    # RETURNS:
    #  [String] the text from the original file   
    def to_s
      @file_text
    end

    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # MATCHES METHODS: Array#first, Array#last, Array#size, Array#each, Array#[]
    #                  calls matched method on @records; otherwise, throws exception
    # EXAMPLE:
    #  message_handler.size => 3
    #  message_handler.balloon => throws NoMethodError    
    def method_missing(sym, *args, &block)
      methods_it_responds_to = [:first, :last, :size, :[], :each]
      if methods_it_responds_to.include?(sym) then @records.send(sym, *args)
      else super
      end
    end

    # runs the code block for all records in the file read by the file handler, in increments of @max_records
    # e.g. by default runs the code block for 10,000 records at a time
    # NAME: do_in_increments
    # DESC: executes code for all records in the file, in groups of @max_records
    # ARGS: 1
    #   block [code block] - the code to execute
    # RETURNS: depends on code block  
    def do_in_increments(&block)
      until @records.empty?
        yield(@records)
        get_records
      end 
    end
  
    private  
  
    # called by initialize
    # reads in a HL7 message as a text file from the given filepath
    # updates @file_text
    def read_message
      raise HL7::BadFileError, "Cannot create FileHandler from empty file" if File.zero?(@file)
      read_file_text
      format_as_segment_text    
    end
  
    # called by read_message
    # reads full text of the file, one character at a time (to handle \r correctly)
    def read_file_text
      HL7.read_file_by_character(@file) do |character|
        @file_text << character == "\r" ? @@eol : character
      end
    end  

    # called by read_message
    # removes empty lines and non-segment lines, and turns all endline characters into the standard segment delimiter
    def format_as_segment_text
      standardize_endline_character
    
      lines = @file_text.split(@@eol)    # split across file's newline character...
      lines.delete_if { |line| line !~ HL7::SEGMENT }  
      raise_error_if(lines.empty?)     
    
      @file_text = lines * HL7::SEG_DELIM     # ...join using message's newline character
    end                                             
  
    # called by polish_text
    # replaces \r, \r\n with @@eol, and adds a newline before MSH segments
    def standardize_endline_character
      @file_text.gsub!('\\r', @@eol)  
      @file_text.gsub!("MSH", "#{@@eol}MSH")
      @file_text.squeeze!(@@eol)
    end

    # called by initialize
    # breaks text into groups of 1 header and 1 body
    # updates @message_text
    def break_into_messages
      headers = extract_headers
      bodies = extract_bodies
      raise_error_if(headers.size != bodies.size)  
    
      for i in (0...headers.size) do
        @message_text << headers[i] + bodies[i]
      end
    end
            
    # called by initialize
    # gets the next @max_size messages, as HL7::Message objects
    # modifies @records
    def get_records
      @records = next_set_of_messages.map { |message| Message.new(message) }
      # @records.flatten! unless @records.first.is_a? Message  # only flatten Arrays, not Messages/Segments etc.       
    end
  
    # called by get_records      
    # returns array of strings containing hl7 message of individual records, based on @file_text
    def next_set_of_messages
      amount = @max_records ? @max_records : @text_as_messages.size
      @message_text.shuffle!    # randomize to get the most diversity out of a record set
      @message_text.shift(amount)
    end
  
    # called by break_into_segments
    # gets the first field of each MSH segment, including the field delimiter (|)
    def extract_headers
      headers = @file_text.scan(HDR)    # all headers
      raise HL7::BadFileError, "FileHandler requires a file containing HL7 messages" if headers.empty?
      headers   
    end

    # called by break_into_segments
    # gets the text between each header
    def extract_bodies
      bodies = @file_text.split(HDR)    # split across headers, yielding bodies of individual records
      bodies.shift                      # first "body" is either empty or garbage
      bodies
    end
  
    # raises BadFileError if @file is discovered not to contain HL7-formatted text
    def raise_error_if(condition_met)
      raise HL7::BadFileError, "#{@file} does not contain valid HL7" if condition_met
    end
    
  end
end