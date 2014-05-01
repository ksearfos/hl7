require 'playground/format_string_parsing_methods'
require 'playground/hl7_name'

module HL7

  # reformats given String as MM/DD/YYYY, or returns the text if it does not represent a valid date
  # HL7 dates are formatted as 'YYYYMMDD'
  # provide a second argument if a delimiter other than '/' is desired
  def self.make_date(date_text, delim = "/")
    return date_text unless hl7_date?(date_text)
    date_components = match_month_day_year(date_text).map { |number| number.to_i }
    date_components * delim   #=> [month, day, year].join('/')   
  end
  
  # true if the given String represents a 4-digit year + 2-digit month + 2-digit day of the month
  # false otherwise
  def self.hl7_date?(text)      
    month, day, year = match_month_day_year(text)
    month?(month) && day?(day) && year?(year)
  end
  
  def self.make_time(time_text)
    return time_text unless hl7_time?(time_text)
    time_components = match_hour_minute_second(time_text)   # don't get rid of leading zeroes for military time
    time_components * ':'
  end
  
  def self.hl7_time?(text)
    hour, minute, second = match_hour_minute_second(text)
    hour?(hour) && minute?(minute) && second?(second)
  end
  
  def self.make_datetime(datetime)
    return datetime unless hl7_date_and_time?(datetime)
    date, time = match_date_time(datetime)
    "#{make_date(date)} #{make_time(time)}"
  end
  
  def self.hl7_date_and_time?(text)
    date, time = match_date_time(text)
    hl7_date?(date) && hl7_time?(time)
  end
  
  def self.make_name(name_text)
    name = HL7::Name.new(name_text)
    return name_text unless name
    name.standard_format
  end
end