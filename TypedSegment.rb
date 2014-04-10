#------------------------------------------
#
# MODULE: HL7
#
# CLASS: HL7::Segment child classes
#
# DESC: Defines a segment in a HL7 message. Specifically adds dynamic functionality for Segment eigenclasses for different
#         types of segments, e.g. a PID eigenclass or a MSH eigenclass.
#       A segment is any number of lines of text, each headed with the same type (3 capital letters, e.g. 'PID') and
#         separated into fields with pipes (|). An eigenclass will add a type and a map of field names to the fields' indices.
#       Since the fields vary by segment type, and we want every segment of the same type to have the same values available,
#         they should be class-level variables. I could create a static class for each segment type, but that is incredibly
#         annoying and requires maintenance--not to mention it gives every Segment the same fields, regardless of type.
#       Instead, we will have 1 eigenclass for each segment type in the message we are reading, created at runtime.
#
# EXAMPLE: new_typed_segment(:PID) => PID class inheriting from HL7::Segment
#          PID.new(text) => object with @type = :PID, @field_index_maps = HL7::PID_FIELDS, class = PID, superclass = Segment
#
# READ-WRITE EIGENCLASS VARIABLES:
#    @type [Symbol] - the segment type
#    @field_index_maps [Hash] - map of field name to its index
#    ====>  Note that these act as class variables to instances of any eigenclasses, and do not exist for instances of Segment
#
# EIGENCLASS METHODS: 
#    self.add(field,index): addes new fieldname-index pair to @field_index_maps
#
# SEGMENT CLASS METHODS:
#    self.subclasses: returns Array of all instantiated subclasses of Segment
#    self.is_eigenclass?: returns false if calling class is Segment; true if it's one of the typed derivatives like PID
#
# SEGMENT INSTANCE METHODS:
#    type: returns value of @type for this object - will be nil if object instantiates Segment directly
#    field_index_maps: returns value of @field_index_maps for this object - will be nil of object instantiates Segment directly
#
# MODULE METHODS:
#    typed_segment(type): returns segment child class called TYPE; creates one first, if necessary
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/12/14 12:53 PM
#
# LAST TESTED: 3/12/14
#
#------------------------------------------

module HL7
  
  class Segment     

    # NAME: Segment.subclasses
    # DESC: finds all subclasses created
    # ARGS: 0
    # RETURNS:
    #  [Array] list of all eigenclasses
    # EXAMPLE:
    #  Segment.subclasses => [ :MSH, :PID ]
    def self.subclasses
      ObjectSpace.each_object(::Class).select{ |klass| klass < self }
    end
    
    # NAME: Segment.is_eigenclass?
    # DESC: determines whether object is instance of Segment or one of its eigenclasses
    # ARGS: 0
    # RETURNS:
    #  [Boolean] true if class is an eigenclass; false otherwise (false if class is Segment)
    # EXAMPLE:
    #  Segment.is_eigenclass? ==> false
    #  PID.is_eigenclass? ==> true
    def self.is_eigenclass?
      self.instance_variable_defined?( :@type )
    end

    # NAME: type
    # DESC: instance-level accessor for the newly added @type variable
    # ARGS: 0
    # RETURNS:
    #  [Symbol] value of @type for self.class, if defined -- otherwise will be nil
    # EXAMPLE:
    #  segment_obj.type ==> nil
    #  pid_obj.type ==> :PID    
    def type
      self.class.type
    end

    # NAME: field_index_maps
    # DESC: instance-level accessor for the newly added @field_index_maps variable
    # ARGS: 0
    # RETURNS:
    #  [Symbol] value of @field_instance_maps for self.class, if defined -- otherwise will be nil
    # EXAMPLE:
    #  segment_obj.field_index_maps ==> nil
    #  pid_obj.field_index_maps ==> { :id=>3, :name=>5, :dob=>6, :sex=>8, :ssn=>19 }    
    def field_index_maps
      self.class.field_index_maps
    end
    
    # eigenclass stuff
    # used by child classes like Pid and Obx
    # everything in here is a class-level variable/method for the eigenclass, which is ironically an instance of Segment
    # to access the variables, use @[variablename]; to access the methods, use class.[methodname]
    class << self
      attr_accessor :type, :field_index_maps

      # NAME: add
      # DESC: add field-index pair to @field_index_maps
      # ARGS: 2
      #  [Symbol] - name of the field
      #  [Integer] - its index, assuming count starts at 1 
      # RETURNS: nothing; modifies @field_index_maps
      # EXAMPLE:
      #  PID.add(:first,1) => { :first=>1, :id=>3, :name=>5, :dob=>6, :sex=>8, :ssn=>19 }     
      def add( field, index )
        field_index_maps[field] = index
      end
    end    
    
  end #class

  # NAME: HL7.new_typed_segment
  # DESC: creates new childclass of Segment with @type = type and @field_index_maps = HL7::[type]_FIELDS
  # ARGS: 1
  #  [Symbol/String] - the segment type/name of the new class 
  # RETURNS:
  #  [Class] new Class, a child of Segment
  # EXAMPLE:
  #  HL7.new_typed_class(:MSH) ==> class named MSH with @type=:MSH and @field_index_maps=MSH_FIELDS
  def self.typed_segment(type)
    # create new class
    t = type.upcase
    return HL7.const_get(t) if HL7.const_defined?(t)
    
    klass = Object.const_set( t.to_s, Class.new(Segment) )   # => new class called TYPE
    klass.type = t.to_sym
  
    # populate @type, @field_index_maps for the class
    hash_name = "#{t}_FIELDS"
    klass.field_index_maps = HL7.const_defined?( hash_name ) ? HL7.const_get( hash_name ) : {}
        
    klass
  end

    def field_index( which )
      if which.is_a?( Integer )
        i = which < 0 ? which : which - 1
        i     # field count starts at 1, but array index starts at 0
      elsif ( which.is_a?(String) || which.is_a?(Symbol) ) && self.class.is_eigenclass?  # @field_index_maps is defined?
        s = which.downcase.to_sym
        i = field_index_maps[s]
        i ? i - 1 : @@no_index_val
      else
        puts "Cannot find field of type #{which.class}"
        @@no_index_val
      end
    end
  end        
end