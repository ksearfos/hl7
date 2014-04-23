  class TextSplitter
    attr_reader :split_text, :text
    SPLIT_INDICATOR = '<SPLIT>'
    
    def initialize(core_text, regex)
      raise "TextSplitter requires a String" unless core_text.is_a? String
      raise "TextSplitter requires a Regexp" unless regex.is_a? Regexp 
      @text = core_text
      split(regex)    # sets @text_by_unit
    end
    
    def rejoin(delimiter)
      @split_text * delimiter  
    end
    
    def size
      @text_by_unit.size
    end
    
    private
    
    def split(pattern)     
      marked_text = @text.gsub(pattern, SPLIT_INDICATOR+'\1'+SPLIT_INDICATOR)
      @split_text = marked_text.split(SPLIT_INDICATOR)
      @split_text.reject!(&:empty?)
    end
  end  
