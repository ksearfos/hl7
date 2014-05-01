=begin -------------------------------------------------------------------
  MODULE: none
  CLASS : SplitText
  DESC  : Defines an object that splits text into units based on a regular expression.
          The text provided is split across the pattern provided.  It will only keep the text
            not matched by the pattern, unless the pattern includes a match group.            
          For example:
            no match group: SplitText.new("1-some 2-text 3-counted", /\d-/)
                            ==> ["some", "text", "counted"]
            match group: SplitText.new("1-some 2-text 3-counted", /(\d)-/)
                            ==> ["1", "some", "2", "text", "3", "counted"] 
          This is in accordance with how the match variable '\1' gets defined.
          
  CLASS VARIABLES:
          none
  CLASS METHODS:
          none

  INSTANCE VARIABLES:
          @value [Array]: the text, once split [READ-ONLY]
               
  INSTANCE METHODS:
          new(text,regex): creates new SplitText with text split across regex
          rejoin(delimiter): joins the split text with the given delimiter
  
  CREATED BY: Kelli Searfos
  LAST UPDATED: 4/23 0959
=end -------------------------------------------------------------------

class SplitText
  attr_reader :value
  SPLIT_INDICATOR = '<SPLIT>'
  MATCH_INDICATOR = '<MATCH>'
    
  def initialize(core_text, regex)
    raise "SplitText requires a String" unless core_text.is_a? String
    raise "SplitText requires a Regexp" unless regex.is_a? Regexp 
    split(core_text, regex)    # sets @value
  end
    
  def rejoin(delimiter)
    @value * delimiter  
  end
    
  private
    
  def split(text, pattern)     
    prepped_text = prepare_to_split(text, pattern)
    split_across_pattern(text)
    split_across_matches
  end
  
  # replaces the pattern with "<SPLIT>" + matched_part_if_there_is_one + "<MATCH>"
  def prepare_to_split(text, pattern)
    text.gsub!(pattern, SPLIT_INDICATOR+'\1'+MATCH_INDICATOR)
  end

  # splits into an array of strings which start with matched_part_if_there_is_one + "<MATCH>"
  def split_across_pattern(text)
    @value = text.split(SPLIT_INDICATOR)
    @value.reject!(&:empty?)   # empty string?
    make_sure_all_elements_have_match_indicator
  end
  
  # splits each element in the array into another array, containing two strings each
  # the first element will always be matched_part_if_there_is_one (or "" otherwise)
  def split_across_matches
    @value.map! { |match_and_text| match_and_text.split(MATCH_INDICATOR) }
    @value.flatten.reject!(&:empty?)   # empty array?
  end

  def make_sure_all_elements_have_match_indicator
    first_value = @value[0]
    return if first_value.include?(MATCH_INDICATOR)
    @value[0] = "#{MATCH_INDICATOR}#{first_value}"
  end
end  
