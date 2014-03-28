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
#    @file_text [String]: stores entire message text
#    @messages [Array]: stores individual records as Message objects
#
# CLASS METHODS: none
#
# INSTANCE METHODS:
#    new(file,limit): creates new FileHandler object and reads in text from file, up to limit records (if specified)
#    to_s: returns String form of FileHandler, which is the text of the file
#    [](index): returns Message at given index
#    each(&block): loops through each record, executing given code
#    method_missing: tries to call method on @messages (Array)
#                    then tries to call method on @file_text (String)
#                    then gives up and throws exception
#    next: gets the next @max_records records and stores them in @records - @records will be empty if there were no more
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/27/14 11:41
#
#------------------------------------------

module HL7
  
  class FileHandler
    
    @@eol = "\n"    # the end-of-line character we are using
    attr_reader :records, :file_text, :file
    
    # NAME: new
    # DESC: creates a new HL7::FileHandler object from a text file
    # ARGS: 1-2
    #  file [String] - complete path to the source file
    #  limit [Integer] - highest number of records to read in from the source file - by default there is no limit
    # RETURNS:
    #  [HL7::FileHandler] newly-created FileHandler
    # EXAMPLE:
    #  HL7::FileHandler.new( "C:\records.txt", 2 ) => new FileHandler pointed to records.txt, with 2 records total  
    def initialize( file, *recs_num )
      raise HL7::FileError, "No such file: #{file}" unless File.exists?(file)
      
      @file = file
      @file_text = ""
      @records = @text_as_messages = []
      # @header_to_body = []   # an array of a hash, e.g. a two dimensional array with [header,body] pairs
      @max_records = recs_num.first
 
      read_message           # updates @file_text
      break_into_messages    # updates @text_as_messages
      get_records
    end

    # NAME: to_s
    # DESC: returns the message handler as a String object - basically the text of the file
    # ARGS: none 
    # RETURNS:
    #  [String] the message handler source in textual form
    # EXAMPLE:
    #  message_handler.to_s => "MSH|...MSH|...MSH|..."     
    def to_s
      @file_text
    end

    # NAME: []
    # DESC: returns record (Message object) at given index
    # ARGS: 1
    #  index [Integer] - the index of the record we want
    # RETURNS:
    #  [Message] an individual Message/record
    # EXAMPLE:
    #  message_handler[2] => Message3    
    def []( index )
      @records[index]
    end

    # NAME: each
    # DESC: performs actions for each record
    # ARGS: 1
    #  [code block] - the code to execute on each component
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  message_handler.each{ |rec| print rec.id + " & " } => 12345 & 12458 & 12045 
    def each
      @records.each{ |rec| yield(rec) }
    end

    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # ARGS: 1+
    #  sym [Symbol] - symbol representing the name of the method called
    #  *args - all arguments passed to the method call
    #  [code block] - optional code block passed to the method call
    # RETURNS: depends on handling
    #     ==>  first checks @records for a matching method
    #     ==>  second checks @file_text for a matching method
    #     ==>  then gives up and throws an Exception
    # EXAMPLE:
    #  message_handler.size => 3 (calls @messages.size)
    #  message_handler.gsub( "*", "|" ) => "MSH*...MSH*...MSH*..."  (calls @file_text.gsub)
    #  message_handler.fake_method => throws NoMethodError    
    def method_missing( sym, *args, &block )
      if Array.method_defined?( sym )
        @records.send( sym, *args )
      elsif String.method_defined?( sym )
        @file_text.send( sym, *args )
      else
        super
      end
    end

    def next
      get_records  
    end
        
    private
        
    # reads in a HL7 message as a text file from the given filepath and stores it in @file_text
    # changes coding to end in \n for easier parsing
    def read_message
      unless File.zero?( @file )
        read_text
        polish_text     
      end
    end
    
    def read_text
      # have to read the file one character at a time in order to handle \r
      file = File.open( @file, "r" )
      file.each_char{ |char| 
        if char == "\r" then @file_text << @@eol
        else @file_text << char
        end
      }
      file.close
    end    

    def polish_text
      @file_text.gsub!( '\\r', @@eol )
      # @file_text.squeeze!( @@eol )                # only need one line break at a time      
      @file_text.gsub!( "MSH", "#{@@eol}MSH" )
      ary = @file_text.split( @@eol )
      ary.delete_if{ |line| line !~ /^\d*[A-Z]{2}[A-Z1]{1}\|/ }  # non-segment lines      
      @file_text = ary.join( SEG_DELIM )    # now glue the pieces back together, ready to be read as HL7 segments
    end                                     # @@eol and SEG_DELIM are probably the same, but there's no guarantee          
        
    # sets @messages to contain all HL7 messages contained within @file_text, as HL7::Message objects
    # can access segments as @messages[index][segment_name]
    # e.g. hl7_messages_array[2][:PID] will return the PID segment of the 3rd record
    def get_records
      all_recs = records_by_text
      @records = all_recs.map{ |msg| Message.new( msg ) }
      @records.flatten!(1) unless @records.first.is_a? Message  # only flatten Arrays, not Messages/Segments etc.       
    end
 
    def break_into_messages
      headers = @file_text.scan( HDR )           # all headers
      bodies = @file_text.split( HDR )[1..-1]    # split across headers, yielding bodies of individual records
      
      for i in (0...headers.size)
        @text_as_messages << headers[i] + '|' + bodies[i]
      end
    end
        
    # returns array of strings containing hl7 message of individual records, based on @file_text
    def records_by_text
      all_recs = []
      amount = ( @max_records ? @max_records : @text_as_messages.size )
      @text_as_messages.shuffle!    # randomize to get the most diversity out of a sample set
      @text_as_messages.shift( amount )
    end
    
  end

end