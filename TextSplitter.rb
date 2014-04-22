module HL7
  class TextSplitter
    attr_reader :heads, :bodies
    
    def initialize(core_text, regex)
      @text = core_text
      split(regex)    # sets @heads, @bodies
    end
   
    def rejoin(delimiter)
      rejoined_text = []
      each_pair { |head_body| rejoined_text << head_body * delimiter }
      rejoined_text
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

    def each_pair(&block)
      for i in 0...size
        yield(pair_at(i))
      end
    end
          
    def pair_at(index)
      [@heads[index], @bodies[index]]
    end
  end  

end