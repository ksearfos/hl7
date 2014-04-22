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
#         the text. It then breaks the text into individual messages and initializes Message objects from those. It will also
#         keep track of each of those Messages and the value separators used by the message.
#       It is assumed that the file is in a valid text format and uses either the Windows-style line endings (\r and \r\n)
#         or the Unix style (\n). It also assumes the file is UTF-8 encoded.
#
# EXAMPLE: FileHandler => "MSH|...MSH|...MSH|..." / [ Message1, Message2, Message 3 ]
#
# CLASS VARIABLES: none; uses HL7.separators[:segment] and modifies HL7.separators
#
# READ-ONLY INSTANCE VARIABLES:
#    @file [String]: the name of the file this FileHandler reads from
#    @messages [Array]: stores individual messages/messages as Message objects
#
# CLASS METHODS: none
#
# INSTANCE METHODS:
#    new(file,limit): creates new FileHandler object and reads in text from file, up to limit messages (if specified)
#    to_s: returns String form of FileHandler, which is the text of the file
#    method_missing: calls certain Array methods on @messages
#                    otherwise throws exception
#    do_in_increments(&block): runs the code block for each set of messages
#    next: gets the next @limit messages and stores them in @messages - @messages will be empty if there were no more
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 4/9 11:44
#
#------------------------------------------

module HL7
  class FileHandler
    EOL = "\n"    # the end-of-line character we are using
    attr_reader :file
    attr_writer :limit
    
    # NAME: new
    # DESC: creates a new HL7::FileHandler object from a text file
    # ARGS: 1-2
    #  file [String] - complete path to the source file
    #  limit [Integer] - highest number of messages to use at one time - 10,000 by default
    # N.B. I've found that storing more than 10,000 Message objects at once usually causes memory allocation errors 
    def initialize(file, limit = 10000)
      raise HL7::NoFileError, file unless File.exists?(file)
    
      @file = file
      @limit = limit                      # the largest size @messages can have
      read_text_from_file                 # sets @file_text
      convert_file_text_to_message_text   # sets @message_text
    end

    # NAME: do_for_each_message
    # DESC: executes code for all messages in the file, in groups of @limit
    # ARGS: 1
    #   block [code block] - the code to execute
    # RETURNS: depends on code block  
    def do_for_all_messages(&block)     
      @message_text.shuffle!
      @message_text.each_slice(@limit) do |set|
        messages = get_messages(set)
        messages.each { |message| yield(message) }
      end
    end
    
    def size
      @message_text.size
    end
    
    # NAME: to_s
    # DESC: returns the message handler as a String object - basically the text of the file
    # ARGS: none 
    # RETURNS:
    #  [String] the text from the original file   
    def to_s
      @file_text
    end
 
    private  
  
    # called by initialize
    def read_text_from_file
      raise HL7::BadFileError, "Cannot create FileHandler from empty file" if File.zero?(@file)
      read_file_text
      standardize_endline_character
      format_as_segment_text    
    end
  
    # called by read_text_from_file
    def read_file_text
      @file_text = ""
      
      HL7.read_file_by_character(@file) do |character|
        @file_text << character == "\r" ? EOL : character
      end
    end  

    # called by read_text_from_file
    def format_as_segment_text      
      lines = get_hl7_lines
      raise_error_if(lines.empty?)           
      @file_text = lines * HL7.separators[:segment]
    end                                             
  
    # called by read_text_from_file
    def standardize_endline_character
      @file_text.gsub!('\\r', EOL)  
      @file_text.gsub!("MSH", "#{EOL}MSH")
    end

    # called by format_as_segment_text
    def get_hl7_lines
      lines = @file_text.split(EOL)
      lines.keep_if { |line| HL7.segment?(line) }  
    end
    
    # called by initialize
    def convert_file_text_to_message_text
      split_file_text_into_headers_and_bodies  
      pair_each_header_to_body                 
      rejoin_headers_and_bodies                
    end    
  
    # called by convert_file_text_to_message_text
    #=> @message_text = [[headers], [bodies]]
    def split_file_text_into_headers_and_bodies
      @message_text = [HL7.extract_headers(@file_text), HL7.extract_bodies(@file_text)]
    end
    
    # called by convert_file_text_to_message_text
    #=> @message_text = [[header1, body1], ..., [headerN, bodyN]]
    def pair_each_header_to_body
      begin
        @message_text.replace(@message_text.transpose) 
      rescue IndexError
        raise HL7::BadFileError, "#{@file} contains unequal number of headers and bodies"  
      end
    end
    
    # called by convert_file_text_to_message_text
    #=> @message_text = ["header1+body1", ..., "headerN+bodyN"]
    def rejoin_headers_and_bodies
      @message_text.map! { |header, body| header + HL7.separators[:segment] + body }
    end
  
    # called by do_for_all_messages
    def get_messages(lines_of_text)
      lines_of_text.map { |message_text| HL7::Message.new(message_text) }  
    end
    
    # raises BadFileError if @file is discovered not to contain HL7-formatted text
    def raise_error_if(condition_met)
      raise HL7::BadFileError, "#{@file} does not contain valid HL7" if condition_met
    end
    
  end
end