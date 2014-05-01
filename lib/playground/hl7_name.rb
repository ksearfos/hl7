module HL7
  class Name
    def initialize(name_text)
      @text = name_text
      @pieces = split_text
    end
  
    # (Prefix) First (MI) Last (Suffix), (Degree)
    def standard_format
      reformat_pieces
      prefix + first + middle + last + suffix + degree    
    end
  
    def prefix
      @pieces[:prefix]
    end
  
    def first
      @pieces[:given]
    end
  
    def middle
      @pieces[:middle]
    end
    
    def last
      @pieces[:surname]
    end
  
    def suffix
      @pieces[:suffix]
    end
  
    def degree
      @pieces[:degree]
    end
  
    private
  
    def split_text
      separate
      remove_id
      raise "Text given is not a name: #{@text}" unless @pieces.size.between?(2, 6)
      make_piece_object
    end
  
    def separate
      @text =~ /^\w+(\W)\w+/   # first non-word character is component delimiter
      @pieces = @text.split($1)
    end
  
    def remove_id
      @pieces.shift if @pieces.first =~ /\d/   # if there are digits, the first piece is an id
    end
  
    def make_piece_object
      piece_array = @pieces
      @pieces = NamePieces.new(*piece_array)
    end
  
    def reformat_pieces
      reformat_prefix
      reformat_middle
      reformat_suffix
      reformat_degree
    end
  
    def reformat_prefix
      prefix = @pieces[:prefix].to_s
      @pieces[:prefix] = prefix.empty? ? "" : "#{prefix} "
    end
  
    def reformat_middle
      middle = @pieces[:middle].to_s
      @pieces[:middle] = middle.empty? ? " " : " #{middle} "   # should at least be space between first/last
    end
  
    def reformat_suffix
      suffix = @pieces[:suffix].to_s
      @pieces[:suffix] = suffix.empty? ? "" : " #{suffix}"
    end
  
    def reformat_degree
      degree = @pieces[:degree].to_s
      @pieces[:degree] = degree.empty? ? "" : ", #{degree}" 
    end
  end

  class NamePieces < Struct.new(:surname, :given, :middle, :suffix, :prefix, :degree)
  end
end