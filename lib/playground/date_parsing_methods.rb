require 'Date'

module HL7
  
  private
  
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
end