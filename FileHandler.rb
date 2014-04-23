require_relative 'TextSplitter'

=begin -------------------------------------------------------------------
  MODULE: HL7
  CLASS : FileHandler
  DESC  : Defines an object to read HL7 messages from a file, convert them to Message objects, and
            manipulate those objects.
          Performs minor reformatting to insure there are no blank lines, and line breaks are done with \n.
          The FileHandler class takes a filepath where HL7 data is stored, reads from it, and
            standardizes the format of the text. It then breaks the text into individual messages
            and initializes Message objects from those, and facilitates iterating through the Messages.
          It is assumed that the input file is in a valid text format and uses either the Windows-style
            line endings (\r and \r\n) or the Unix style (\n). It also assumes the file is UTF-8 encoded.
  
  CLASS VARIABLES:
          none; uses HL7::SEGMENT_DELIMITER
  CLASS METHODS:
          none

  INSTANCE VARIABLES:
          @file [String]: the name of the file this FileHandler reads from [READ-ONLY]     
  INSTANCE METHODS:
          new(file,limit): creates new FileHandler object with a base file and message limit
          to_s: returns String form of FileHandler, which is the text of the file
          do_for_all_messages(&block): runs the code block for each message, in subsets of size @limit
  
  CREATED BY: Kelli Searfos
  LAST UPDATED: 4/22 1144
=end -------------------------------------------------------------------

module HL7
  class FileHandler
    EOL = "\n"    # the end-of-line character we are using
    attr_reader :file
    
    # PURPOSE:  creates a new HL7::FileHandler object from a text file
    # REQUIRES: file [String] - complete path to the source file
    # OPTIONAL: limit [Integer] - highest number of messages to process at one time - 10,000 by default
    # RETURNS:  new FileHandler 
    # N.B. I've found that processing more than 10,000 Message objects at once generally causes NoMemoryErrors 
    def initialize(file, limit = 10000)
      raise HL7::NoFileError, file unless File.exists?(file)
    
      @file = file
      @limit = limit                      # the largest number of messages to use at one time
      read_text_from_file                 # sets @file_text
      convert_file_text_to_message_text   # sets @messages_as_text
    end

    # PURPOSE:  creates Message objects as needed and iterates through them, performing desired tasks
    # REQUIRES: block [code block] - the code to execute
    # RETURNS:  depends on code block  
    def do_for_all_messages(&block) 
      raise ArgumentError, "FileHandler#do_for_all_messages expects a code block" unless block_given?    
      @messages_as_text.shuffle!
      @messages_as_text.each_slice(@limit) do |set|
        messages = get_messages(set)
        messages.each { |message| yield(message) }
      end
    end

    # PURPOSE:  determines total the number of messages in the given file
    # REQUIRES: nothing
    # RETURNS:  [Integer] total number of messages    
    def size
      @messages_as_text.size
    end

    # PURPOSE:  transforms the FileHandler into a String object
    # REQUIRES: nothing
    # RETURNS:  [String] the underlying file text 
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
        @file_text += character == "\r" ? EOL : character
      end
    end  

    # called by read_text_from_file
    def format_as_segment_text      
      lines = get_hl7_lines
      raise_error_if(lines.empty?)           
      @file_text = lines * HL7::SEGMENT_DELIMITER
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
      split_ready_text = @file_text.gsub(HL7::HEADER_REGEX, '>>>\1')
      @messages_as_text = split_ready_text.split('>>>')
      @messages_as_text.shift
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