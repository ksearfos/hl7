#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::Field
#
# DESC: Defines a field in a HL7 message - provides elegant handling of components
#       A field is the piece of text between pipes (|), and can be broken into components with a caret (^)
#       The field class keeps track of both the original text of the field, as well as breaks it into
#         an array of its components, which can be quickly accessed by index
#       A segment will generally contain multiple fields
#
# EXAMPLE: Attending doctor => "12345^Smith^John^^^MD" / ["12345","Smith","John",,,"MD"]
# 
# CLASS VARIABLES: none; uses HL7::FIELD_DELIM and HL7::COMP_DELIM
#
# READ-ONLY INSTANCE VARIABLES:
#    @original_text [String]: stores the text originally found in the field, e.g. "SMITH^JOHN^W"
#    @components [Array]: stores each component in the field, e.g. [ "SMITH", "JOHN", "W" ]
#
# CLASS METHODS: none
#
# INSTANCE METHODS:
#    new(field_text): creates new Field object based off of given text
#    to_s: returns String form of Field
#    [](index): returns component at given index - count starts at 1
#    each(&block): loops through each component, executing given code
#    method_missing: tries to call method on @components (Array)
#                    then tries to call method on @original_text (String)
#                    then gives up and throws exception
#    view: prints component to stdout in readable form, headed by component index
#    as_date: prints value of Field formatted as a date
#    as_time: prints value of Field formatted as a time
#    as_datetime: prints value of Field formatted as a date + a time
#    as_name: prints value of Field formatted as a name
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/27/14 11:41
#
#------------------------------------------
module HL7

  class Field  
    attr_accessor :components, :original_text
    
    # NAME: new
    # DESC: creates a new HL7::Field object from its original text
    # ARGS: 1
    #  field_text [String] - the text of the field, without surrounding pipes 
    # RETURNS:
    #  [HL7::Field] newly-created Field
    # EXAMPLE:
    #  HL7::Field.new( "a^b^c" ) => new Field with text "a^b^c" and components ["a","b","c"]
    def initialize( field_text, component_delim='^' )
      @original_text = field_text
      @components = field_text.split( component_delim )    # an array of strings
    end 
    
    # NAME: to_s
    # DESC: returns field as a String object
    # ARGS: none 
    # RETURNS:
    #  [String] the field in textual form
    # EXAMPLE:
    #  field.to_s => "a^b^c"
    def to_s
      @original_text
    end
    
    # NAME: each
    # DESC: performs actions for each component of the field
    # ARGS: 1
    #  [code block] - the code to execute on each component
    # RETURNS: nothing, unless specified in the code block
    # EXAMPLE:
    #  field.each{ |c| print c + " & " } => a & b & c
    def each
      @components.each{ |comp| yield(comp) }
    end
    
    # NAME: []
    # DESC: returns component at given index
    # ARGS: 1
    #  index [Integer] - the index we want the component for -- note that the count starts at 1
    # RETURNS:
    #  [String] the value of the component
    # EXAMPLE:
    #  field[2] => "b"
    def [](index)
      i = index < 0 ? index : index - 1
      @components[i]
    end
    
    # NAME: method_missing
    # DESC: handles methods not defined for the class
    # ARGS: 1+
    #  sym [Symbol] - symbol representing the name of the method called
    #  *args - all arguments passed to the method call
    #  [code block] - optional code block passed to the method call
    # RETURNS: depends on handling
    #     ==>  first checks @components for a matching method
    #     ==>  second checks @original_text for a matching method
    #     ==>  then gives up and throws an Exception
    # EXAMPLE:
    #  field.size => 3 (calls @components.size)
    #  field.gsub( "*", "^" ) => "a*b*c" (calls @original_text.gsub)
    #  field.fake_method => throws NoMethodError
    def method_missing( sym, *args, &block )
      if Array.method_defined?( sym )       # a Field is generally a group of components
        @components.send( sym, *args )
      elsif String.method_defined?( sym )   # but we might just want String stuff, like match() or gsub
        @original_text.send( sym, *args )
      else
        super
      end
    end
    
    # NAME: view
    # DESC: displays the components, clearly enumerated
    # ARGS: none
    # RETURNS: nothing; writes to stdout
    # EXAMPLE:
    #  field.view => 1:a, 2:b, 3:c
    #  field.view => 1:Smith, 2:John, 3:, 4:III
    def view
      puts @original_text
      
      last = @components.size - 1
      for i in 0..last
        print "#{i}:#{@components[i]}"
        print i == last ? "\n" : ", "
      end
    end
    
    # NAME: as_date
    # DESC: returns value formatted as a date
    # ARGS: 0-1
    #  delim [String] - delimiter to use in reformatting -- '/' by default
    # RETURNS:
    #  [String] the value of the field reformatted as a date
    # EXAMPLE:
    #  field.as_date => 4/15/1983
    #  field.as_date( "-" ) => 4-15-1983
    def as_date( delim = "/" )
      HL7.make_date( @original_text, delim )
    end

    # NAME: as_time
    # DESC: returns value formatted as a time
    # ARGS: 0-1
    #  military [Boolean] - set to true if we want to use the 24-hr clock -- false by default
    # RETURNS:
    #  [String] the value of the field reformatted as a time
    # EXAMPLE:
    #  field.as_time => 7:23:56 PM
    #  field.as_time( true ) => 19:23:56
    def as_time( military = false )
      HL7.make_time( @original_text, military )
    end

    # NAME: as_datetime
    # DESC: returns value formatted as a date followed by a time
    # ARGS: none
    # RETURNS:
    #  [String] the value of the field reformatted as a date + a time
    # EXAMPLE:
    #  field.as_datetime => 4/15/1983 7:23:56 AM
    def as_datetime
      HL7.make_datetime( @original_text )
    end

    # NAME: as_name
    # DESC: returns value formatted as a person's name
    # ARGS: none
    # RETURNS:
    #  [String] the value of the field reformatted as a name
    # EXAMPLE:
    #  field.as_name => JOHN W SMITH JR
    def as_name
      HL7.make_name( @original_text )
    end
    
  end
  
end #this is in a module, remember?