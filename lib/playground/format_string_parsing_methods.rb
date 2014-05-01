require 'Date'

module HL7
  
  private
  
  # ----- DATE ----- #
  # true if the given text represents a 4-digit year, occurring in a realistic century range      
  def self.year?(text)
    current_year = Date.today.year
    text.to_i.between?(current_year - 200, current_year + 50)
  end
  
  # true if the given text represents a month from 1 (January) to 12 (December)
  def self.month?(text)
    text.to_i.between?(1, 12)
  end
  
  # true if the given text represents a day of the month from 1 to 31
  # does not check that the day of the month actually occurs in a specific month
  #+ meaning 31 will return true even if the month is February
  def self.day?(text)
    text.to_i.between?(1, 31)      
  end
  
  # returns array representing month, day of the month, and year from the given string
  #+ [month, day, year]
  def self.match_month_day_year(date_string)
    date_string.match(/^(\d{4})(\d{2})(\d{2})/)  # matched components: year, month, day 
    [$2, $3, $1]   # if we're reformatting, we want this order; if we aren't the order doesn't matter
  end

  # ----- TIME ----- #
  # true if the given text represents an hour on the 24-hour clock from 00 (midnight) and 23 (11 PM)
  def self.hour?(text)
    text.to_i.between?(0, 23)
  end
  
  # true if the given text represents a part of the hour from 00 to 59
  # note that this can be used for both minutes AND seconds, despite the name
  def self.minute?(text)
    text.to_i.between?(0, 59)
  end
  
  # true if either no text was given or the text passed is a part of the minute from 00 to 59
  def self.second?(*possible_text)
    second = possible_text.first
    second.nil? || minute?(second)   # see note above
  end
  
  # returns an array representing the hour, minute, and (if included) second from the string given
  #+ [hour, minute, nil] or [hour, minute, second]
  def self.match_hour_minute_second(time_string)
    time_string.match(/^(\d{2})(\d{2})(\d{2})?/)   # matched components: hour, day, second (if present)
    $3 ? [$1, $2, $3] : [$1, $2]
  end
  
  # ----- DATE + TIME ----- #
  def self.match_date_time(datetime_string)
    datetime_string.match(/^(\d{8})(\d+)/)
    [$1, $2]
  end
end