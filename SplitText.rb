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
    text.gsub!(pattern, SPLIT_INDICATOR+'\1'+SPLIT_INDICATOR)
    @value = text.split(SPLIT_INDICATOR)
    @value.reject!(&:empty?)
  end
end  
