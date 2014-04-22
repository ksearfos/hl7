module HL7
  class TextSplitter
    attr_reader :heads, :bodies, :pairs
    
    def initialize(core_text, regex)
      @text = core_text
      split(regex)    # sets @heads, @bodies
      @pairs = [@heads, @bodies].transpose   #=> [ [h1,b1], [h2,b2], ... ]
    end
       
    def rejoin(delimiter)
      @pairs.map { |head_body| head_body * delimiter }
    end
    
    def size
      @heads.size   # @bodies.size is the same size, of course
    end
    
    private
    
    def split(pattern)
      @heads = @text.scan(pattern)
      @bodies = @text.split(pattern)
      @bodies.shift    # due to the way split works, @bodies.first is either empty or garbage  
      raise HL7::BadTextError "Unequal number of heads and bodies" if @heads.size != @bodies.size
    end
  end  

end