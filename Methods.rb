#------------------------------------------
#
# MODULE: HL7
#
# DESC: Collection of methods intended for output and data validation when working
#         with HL7 messages
#
# CLASS-LEVEL METHODS:
#    find_field(value) - finds segment and index of the given field, returning field string as "seg#"
#    get_data(messages,field) - gathers a list of all values of field appearing in the messages
#    make_hl7_date(str,delim) - takes date in standard format, and puts it into HL7 date format
#    make_date(date,delim) - takes String representing a date and puts it into more recognizable format
#    make_time(time,military) - takes String representing a time and puts it into more recognizable format
#    make_datetime(datetime) - takes String representing a date and a time and puts it into more recognizable format
#    make_name(name) - takes String representing a name (^-delimited) and puts it into more recognizable format
#    is_suffix?(val) - determines whether value given represents a proper name suffix (e.g. III or Jr.)
#    is_year?(val) - determines whether value given represents a valid year
#    is_month?(val) - determines whether value given represents a valid month of the year
#    is_day?(val) - determines whether value given represents a valid day of the month
#    is_hour?(val) - determines whether value given represents a valid hour of the day
#    is_min_sec?(val) - determines whether value given represents a valid minutes or seconds value
#    is_date?(val) - determines whether value given represents a valid date, by HL7 formatting standards
#    is_time?(val) - determines whether value given represents a valid time, by HL7 formatting standards
#    is_datetime?(val) - determines whether value given represents a valid date + time, by HL7 formatting standards
#    is_numeric?(val) - determines whether value given is numeric, by HL7 formatting standards
#    is_struct_num?(val) - determines whether value given is a structured numeric, by HL7 formatting standards
#    is_timestamp?(val) - determines whether value given is a timestamp, by HL7 formatting standards
#    is_text?(val) - determines whether value given is (unformatted) text, by HL7 formatting standards
#    has_correct_format?(value,format) - determines whether the value given is of the format specified
#
# CREATED BY: Kelli Searfos
#
# LAST UPDATED: 3/12/14 13:06
#
# LAST TESTED: 3/12/14
#
#------------------------------------------
module HL7                         

  # NAME: find_field
  # DESC: returns given field in String form, e.g. "seg#"
  # ARGS: 1
  #   value [String/Symbol] - the name of the field
  # RETURNS:
  #   [String] segment and index where the field is located, or empty String if not found
  #       ==>  if there are multiple occurrences of the same field, such as :set_id, uses first matching segment it finds
  # EXAMPLE:
  #   HL7.find_field(:patient_id) => "pid3"
  def self.find_field( value )
    seg = ""  
    field = ""
    key = value.to_sym
    
    HL7Test::Segment.subclasses.each{ |cl|
      fim = cl.field_index_maps
      if fim.has_key?(key)
        seg = cl.to_s
        field = fim[key].to_s    # the field's index
        break    
      end
    }

    seg.downcase + field         # "seg#"
  end
  
  # NAME: get_values
  # DESC: returns a list of all values appearing in the given field in the given messages
  # ARGS: 2
  #   messages [Array] - list of HL7::Messages
  #   field [String] - field whose values we seek, in fetch_field() format ("seg#")
  # RETURNS:
  #   [Array] all unique values appearing in that field
  # EXAMPLE:
  #   HL7.get_values(msg_list,"pid3") => all patient IDs appearing in the messages of msg_list
  def self.get_data( messages, field )
    data = []
    messages.each{ |message| data << message.fetch_field(field) }
    data.flatten!   # we do want to flatten Fields here, so we can get to the text underneath
    data.uniq!
    data.keep_if{ |datum| !datum.to_s.empty? }
  end

# ---------------------------- Methods to add formatting ---------------------------- #

  # NAME: make_hl7_date
  # DESC: returns standard date value formatted as YYYYMMDD
  #       essentially reverses make_date()
  # ARGS: 1-2
  #   str [String] - date in more standard format, e.g. MM/DD/YYYY
  #   delim [String] - delimiter to use to find the date components -- '/' by default
  # RETURNS:
  #   [String] the value of the field reformatted as a date HL7 will recognize
  # EXAMPLE:
  #   HL7.make_date( "11/05/1903" ) => 19031105
  #   HL7.make_date( "11-05-1903", "-" ) => 19031105
  def self.make_hl7_date( str, delim='/' )
    parts = str.split(delim)
    mo = parts[0]
    day = parts[1]
    year = parts[2]
    year + mo + day 
  end
  
# ---------------------------- Methods to add formatting ---------------------------- #

  # NAME: make_date
  # DESC: returns value formatted as a date
  #       HL7 dates are generally stored in the following format: YYYYMMDD
  # ARGS: 1-2
  #   date [String] - string to be put into date format -- should be 8 digits
  #   delim [String] - delimiter to use in reformatting -- '/' by default
  # RETURNS:
  #   [String] the value of the field reformatted as a date
  # EXAMPLE:
  #   HL7.make_date( "19031105" ) => 11/05/1903
  #   HL7.make_date( "19031105", "-" ) => 11-05-1903
  # Used by HL7::Field
  def self.make_date( date, delim = "/" )
    yr = date[0...4]
    mon = date[4...6]
    day = date[6...8]
    mon + delim + day + delim + yr
  end
    
  # NAME: make_time
  # DESC: returns value formatted as a time
  #       HL7 times are generally stored in 24-hr format, with seconds optional: HHMMSS
  # ARGS: 1-2
  #   time [String] - string to be put into time format -- should be 4 or 6 digits
  #   military [Boolean] - if true, use AM/PM and if false, use 24-hr clock -- false by default
  # RETURNS:
  #   [String] the value of the field reformatted as a time -- loses leading 0 if not military time
  # EXAMPLE:
  #   HL7.make_time( "192413" ) => 7:24:13 PM
  #   HL7.make_time( "1924", true ) => 19:24
  # Used by HL7::Field
  def self.make_time( time, military = false )
    str = ""
    hr = time[0...2]
    min = time[2...4]
    sec = time[4...6]
    
    if military
      str = "#{hr}:#{min}" 
      str << ":#{sec}" unless sec.to_s.empty?
    else
      hr = hr.to_i     # removes leading 0 and makes math easy
      ampm = ( hr > 12 ? "PM" : "AM" )
      hr = ( hr > 12 ? (hr-12).to_s : hr.to_s )   # turn it back into a string, with the right value
        
      str = "#{hr}:#{min}"
      str << ":#{sec}" unless sec.to_s.empty?
      str << " #{ampm}"
    end
      
    str
  end
  
  # NAME: make_datetime
  # DESC: returns value formatted as a date followed by a time
  #       HL7 datetimes are generally stored as date + time in the same component: YYYYMMDDHHMMSS
  # ARGS: 1
  #   datetime [String] - string to be put into datetime format -- should be 12 or 14 digits (seconds are optional)
  # RETURNS:
  #   [String] the value of the field reformatted as a date + a time -- uses default argments for date() and time()
  # EXAMPLE:
  #   HL7.make_datetime( "190311051924" ) => 11/05/1903 7:24 PM
  # Used by HL7::Field
  def self.make_datetime( datetime )
    date = datetime[0...8]
    time = datetime[8..-1] 
    make_date( date ) + " " + make_time( time, true )
  end

  # NAME: make_name
  # DESC: returns value formatted as a person's name
  #       HL7 names are generally stored in one of two forms:
  #         1. XPN, like a patient name: Last^First^Middle^Suffix
  #         2. XCN, like a doctor's name: ID^Last^First^Middle^Suffix^Prefix^Degree
  #       This method handles both, but if it is passed an ID it ignores the ID
  # ARGS: 1
  #   name [String] - string to be put into datetime format -- should be 2-6 ^-delimited sections
  # RETURNS:
  #  [String] the value of the field reformatted as a name
  # EXAMPLE:
  #  HL7.as_name( "Smith^John^W^III^Dr.^MD" ) => Dr. John W Smith III, MD
  #  HL7.as_name( "DOE^JANE^^SR." ) => JANE DOE SR.
  def self.make_name( name )
    pieces = name.split( @separators[:comp] )
    pieces.shift if pieces[0] =~ /\d+/     # IDs include digits, and this is either an ID or a Surname
     
    last = pieces[0].to_s
    first = pieces[1].to_s
    mi = pieces[2].to_s
    sfx = pieces[3].to_s
    pfx = pieces[4].to_s
    deg = pieces[5].to_s
  
    mi_str = ( !mi.empty? ? " #{mi}" : "" )      # starts with space
    sfx_str = ( !sfx.empty? ? " #{sfx}" : "" )   # starts with space
    pfx_str = ( !pfx.empty? ? "#{pfx} " : "" )   # ends with space
    deg_str = ( !deg.empty? ? ", #{deg}" : "" )  # starts with comma
  
    # PFX FIRST MI LAST SFX, DEG
    pfx_str + first + mi_str + " " + last + sfx_str + deg_str
  end

# ---------------------------- Methods to verify formatting ---------------------------- #

  def self.is_name?( val )
    parts = val.is_a?(Array) ? val.flatten : val.split(HL7Test.separators[:comp]) 
    return false if parts.empty?

    first_last = /^[A-Z][A-z \-]*/
    return false unless parts[0] =~ first_last       # last name - required
    return false unless parts[1] =~ first_last       # first name - required
    return false unless parts[2].to_s.empty? || parts[2] =~ /^[A-Z]/    # middle name/initial - optional    
    return false unless parts[3].to_s.empty? || is_suffix?(parts[3])    # suffix - optional
    return false unless parts[4].to_s.empty? || parts[4] =~ /^[A-Z]/    # prefix - optional  
    return false unless parts[5].to_s.empty? || parts[5] =~ /^[A-Z]/    # degree - optional   
    true   
  end
    
  # NAME: is_suffix?
  # DESC: determines whether the value given could represent a name suffix
  #       a suffix is either a roman numeral or Jr/Sr
  # ARGS: 1
  #   value [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a suffix, false otherwise
  # EXAMPLE:
  #  HL7.is_suffix?( "III" ) => true
  #  HL7.is_suffix?( "rainbow" ) => false 
  def self.is_suffix?( val )
    return true if val.to_s.empty?
    
    val.chomp!('.')
    val.upcase!
    allowed = %w( JR SR MD DO DDS DR )
    val =~ /^[XVI]+$/ || allowed.include?( val )     # roman numeral, e.g. III for The 3rd, or value in the list      
  end
  
  # NAME: is_year?
  # DESC: determines whether the value given could represent a year, such as in a date
  #       a year is 4 digits leading with 19- or 20-
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a year, false otherwise
  # EXAMPLE:
  #  HL7.is_year?( "1984" ) => true
  #  HL7.is_year?( "183" ) => false   
  def self.is_year?( val )
    yr = val.to_s
    century = yr[0...2]
    
    # a 4-digit number in the 20th or 21st century
    yr =~ /^\d{4}$/ && ( century == "19" || century == "20" )
  end

  # NAME: is_month?
  # DESC: determines whether the value given could represent a month, such as in a date
  #       a month is 2 digits representing a value from 1-12
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a month, false otherwise
  # EXAMPLE:
  #  HL7.is_month?( "05" ) => true
  #  HL7.is_month?( "13" ) => false   
  def self.is_month?( val )
    mo = val.to_i    # Strings with non-digit characters get translated into 0
    mo.between?( 1, 12 )
  end

  # NAME: is_day?
  # DESC: determines whether the value given could represent a day, such as in a date
  #       a month is 2 digits representing a value from 1-31
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a day, false otherwise
  # EXAMPLE:
  #  HL7.is_day?( "25" ) => true
  #  HL7.is_day?( "41" ) => false    
  def self.is_day?( val )
    day = val.to_i   # Strings with non-digit characters get translated into 0
    day.between?( 1, 31 )
  end

  # NAME: is_hour?
  # DESC: determines whether the value given could represent an hour, such as in a time
  #       an hour is 2 digits representing a value from 0-23  (because midnight is 00 in military time)
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like an hour, false otherwise
  # EXAMPLE:
  #  HL7.is_hour?( "00" ) => true
  #  HL7.is_hour?( "25" ) => false     
  def self.is_hour?( val )
    return false if val !~ /^\d{2}$/    # 2 digits, and only 2 digits?
    
    hr = val.to_i
    hr.between?( 0, 23 )   # don't know if it's military time or not
  end

  # NAME: is_min_sec?
  # DESC: determines whether the value given could represent a minute or a second, such as in a time
  #       a minute/second is 2 digits representing a value from 0-59
  #       Note that this can be used for milliseconds and other similar units, but HL7 generally doesn't include those
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a minute/seconds value, false otherwise
  # EXAMPLE:
  #  HL7.is_hour?( "08" ) => true
  #  HL7.is_hour?( "632" ) => false      
  def self.is_min_sec?( val )
    return false if val !~ /^\d{2}$/
    
    min = val.to_i
    min.between?( 0, 59 )
  end

  # NAME: is_datetime?
  # DESC: determines whether the value given is a properly-formatted datetime
  #       see make_datetime() for details
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a timestamp, false otherwise
  # EXAMPLE:
  #  HL7.is_datetime?( "200412031108" ) => true
  #  HL7.is_datetime?( "1314" ) => false    
  def self.is_datetime?( val )
    date = val[0...8]
    time = val[8..-1]
    
    is_date?(date) && is_time?(time)
  end

  # NAME: is_date?
  # DESC: determines whether the value given is a properly-formatted date
  #       see make_date() for details
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a date, false otherwise
  # EXAMPLE:
  #  HL7.is_date?( "20041203" ) => true
  #  HL7.is_date?( "18121532" ) => false 
  def self.is_date?( val )
    yr = val[0...4]
    mo = val[4...6]
    day = val[6...8]
    
    is_year?(yr) && is_month?(mo) && is_day?(day)
  end  
  
  # NAME: is_time?
  # DESC: determines whether the value given is a properly-formatted time
  #       see make_time() for details
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value looks like a date, false otherwise
  # EXAMPLE:
  #  HL7.is_time?( "1203" ) => true
  #  HL7.is_time?( "2601" ) => false 
  def self.is_time?( val )
    return false if val !~ /^\d{4}\d{2}?$/    # 4 or 6 digits
    
    hr = val[0...2]
    min = val[2...4]
    sec = val[4...6]

    is_hour?(hr) && is_min_sec?(min) && ( sec.empty? || is_min_sec?(sec) )   # seconds value is optional, remember
  end    

  # NAME: is_numeric?
  # DESC: determines whether the value given is a numeric
  #       a HL7 numeric is either an integer or a decimal, with optional +/- sign, and it might be space-padded
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value is numeric, false otherwise
  # EXAMPLE:
  #  HL7.is_numeric?( " - 1.34 " ) => true
  #  HL7.is_numeric?( "<26" ) => false     
  def self.is_numeric?( str )
    str.strip!
    str.tr!( " ", "" )                    # remove spaces
    return false if str.empty?
     
    return false if str[0] !~ /-|\+|\d/   # first character is a digit or positive/negative sign?
    return false if str[-1] !~ /\d/       # last character is a digit?

    middle = str[1..-2] 
    return true if middle.empty?
    return middle =~ /^\d*\.?\d*$/        # middle is nothing but digits and a possible decimal point
  end

  # NAME: is_struct_num?
  # DESC: determines whether the value given is a structured numeric
  #       a HL7 structured numeric is an inequality, a ratio, an interval , or a categorical result
  #       that is, <3.4, 4:5 or 4/5, 4.5 - 10.0, 2+
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value is a structured numeric, false otherwise
  # EXAMPLE:
  #  HL7.is_struct_num?( " <= -1.34 " ) => true
  #  HL7.is_struct_num?( "26" ) => false   
  def self.is_struct_num?( str )
    str.strip!
    str.tr!( " ", "" )              # remove spaces 
    return false if str.empty?
    return false if is_numeric?( str )
    
    # first character(s), if not digits, are <>, <, >, <=, >=
    allowed_beg = [ "<>", "<", ">", "<=", ">=", "" ]
    seps = /[\/\-+:]/   # period is allowed too, but will be found with is_numeric?
    str.strip!
    str.tr!( " ", "" )               # remove spaces 
    
    # first, does it begin with an allowed character (or nothing)?   
    num_i = str.index( /-?\d/ )      # beginning of numeric
    return false unless num_i        # if there is no match for a - or digit, this isn't a structured numeric
    beg = str[0...num_i]             # portion of string before numeric
    return false unless allowed_beg.include?( beg )
    
    # next, find the separator
    num_i += 1 if str[num_i] == '-'  # leaving a negative number will screw up the regex match
    rest = str[num_i..-1]            # portion of string beginning with numeric
    m = rest.match( /[\/\-+:]/ )
    sep = m ? m[0] : ""              # separator, if there is one
    
    # is everything else numeric?
    if sep.empty?
      return false unless is_numeric?( rest )
    else
      nums = rest.split( sep )       # numeric portions of string
      if sep == '+'
        return false unless nums.size == 1 && is_numeric?( nums[0] )
      else
        return false unless nums.size == 2
        nums.each{ |n| return false unless is_numeric?( n ) }
      end
    end
    
    # if we are here, str is not a numeric, there is a valid beginning piece and a valid
    #+ separator, and the rest is numeric, so...
    true
  end

  # NAME: is_timestamp
  # DESC: determines whether the value given is a timestamp
  #       a HL7 timestamp is a date (with dashes) followed by a time in military time
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value is text, false otherwise
  # EXAMPLE:
  #  HL7.is_timestamp?( "10-18-2011 23:59" ) => true
  #  HL7.is_timestamp?( "26" ) => false    
  def self.is_timestamp?( str )
    parts = str.split( " " )
    date = parts[0]
    time = parts[1]     # some timestamps end with a space, so don't take last index
    
    return false unless date =~ /^\d{2}\-\d{2}\-\d{4}$/
    return false unless time =~ /^\d{2}:\d{2}$/
    return false unless is_date?( make_hl7_date(date,'-') )
    is_time?( time.tr!(':','') )     
  end  
  
  # NAME: is_text
  # DESC: determines whether the value given is proper text
  #       a HL7 text is really any String that isn't a numeric or structured numeric
  # ARGS: 1
  #   val [String] - value to be checked
  # RETURNS:
  #  [Boolean] true if the value is text, false otherwise
  # EXAMPLE:
  #  HL7.is_text?( "I like candy" ) => true
  #  HL7.is_numeric?( "26" ) => false    
  def self.is_text?( str )
    # value is text (matches 'TX' type) if there is a value, and that value doesn't match any other type
    is_other = ( is_numeric?(str) || is_struct_num?(str) || is_timestamp?(str) )
    !is_other
  end
  
  # NAME: has_correct_format?
  # DESC: determines whether the value is in the format given
  #       specifically intended for verifying that OBX.5 matches the type specified in OBX.2, but useful for any
  #         value whose type is either 'TX' (text), 'TS' (timestamp), 'NM' (numeric), or 'SN' (structured num)
  # ARGS: 2
  #   value [String] - value whose format we want to verify
  #   format [String] - the format it is supposed to have -- either 'TX', 'TS', 'NM', or 'SN', or the full typename
  # RETURNS:
  #  [Boolean] true if the value is of the format specified, false otherwise
  # EXAMPLE:
  #  HL7.has_correct_format?( "abc", "TX" ) => true
  #  HL7.has_correct_format?( "1.2", "numeric" ) => true
  #  HL7.has_correct_format?( "12/16/84", "SN" ) => false   
  # ==> most common usage: HL7.has_correct_format?( record[:OBX].value, record[:OBX].value_type )
  def self.has_correct_format?( value, format )
    case format
    when 'NM',"numeric" then is_numeric?( value )
    when 'SN',"structured numeric" then is_struct_num?( value )
    when 'TX',"text" then is_text?( value )
    when 'TS',"timestamp" then is_timestamp?( value )
    else false    # not a valid type, so how could we match it?
    end
  end  
end