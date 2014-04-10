# the "shell" or starting values for a Segment object
# segments work with these values, but do a lot more with them
class SegmentText
  SEGMENT_PATTERN = /([A-Z]{2}[A-Z1]{1})\|/    # note the parentheses - they are kind of hard to see
  attr_reader :type, :text
  
  def initialize(text, line)
    separate_type_from_text(text)   # sets @type, @text
  end
  
  private
  
  def separate_type_from_text(text)
    text.match(/#{SEGMENT_REGEX}(.*)/)
    @type = $1.to_sym
    @text = $2
  end
end

class NilSegmentText < Struct
  def type
    :""
  end
end