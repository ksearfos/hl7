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
  SPLIT_INDICATOR = '<SPLIT>'
  MATCH_INDICATOR = '<MATCH>'
    
  def initialize(core_text, regex)
    raise "SplitText requires a String" unless core_text.is_a? String
    raise "SplitText requires a Regexp" unless regex.is_a? Regexp 
    @value = core_text
    @pattern = regex
    mark_with_split_points
  end
  
  def split
    split_across_pattern
    split_across_matches  
    @split_text.flatten
  end
  
  # rejoins text, but doesn't actually change @value  
  def rejoin(split_point_delimiter, match_point_delimiter = "")
    rejoined = @value.gsub(SPLIT_INDICATOR, split_point_delimiter) 
    rejoined.gsub!(MATCH_INDICATOR, match_point_delimiter)
    rejoined.reverse.chomp(split_point_delimiter).reverse
  end
  
  # "peek" at @value, getting an idea of what the remaining text is
  # returns a 1-dimensional array
  # e.g. ["1", "carrot"] or ["apple"]
  def peek
    split_value = split
    split_value.reject(&:empty?)
  end  
  
  private

  # replaces the pattern with "<SPLIT>" + matched_part_if_there_is_one + "<MATCH>" 
  # e.g. "<SPLIT>1<MATCH>carrot" or "<SPLIT><MATCH>apple"   
  def mark_with_split_points   
    @value.gsub!(@pattern, SPLIT_INDICATOR+'\1'+MATCH_INDICATOR)
  end

  # splits into an array of strings which start with matched_part_if_there_is_one + "<MATCH>"
  # e.g. "1<MATCH>carrot" or "<MATCH>apple"
  def split_across_pattern
    @split_text = @value.split(SPLIT_INDICATOR)
    @split_text.reject!(&:empty?)   # empty string?
    make_sure_all_elements_have_match_indicator
  end
  
  # splits each element in the array into another array, containing two strings each
  # the first element will always be matched_part_if_there_is_one (or "" otherwise)
  # e.g. ["1", "carrot"] or ["", "apple"]
  def split_across_matches
    @split_text.map! { |match_and_text| match_and_text.split(MATCH_INDICATOR) }
  end

  def make_sure_all_elements_have_match_indicator
    first_value = @split_text[0]
    return if first_value.include?(MATCH_INDICATOR)
    @split_text[0] = "#{MATCH_INDICATOR}#{first_value}"
  end
end  
