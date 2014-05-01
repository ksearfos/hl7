require 'playground/date_parsing_methods'

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
end