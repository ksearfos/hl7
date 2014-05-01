require 'spec_helper'

describe SplitText do
  it "requires text" do
    expect { SplitText.new(/nontext/, //) }.to raise_exception  
  end
  
  it "requires a regexp to split across" do
    expect { SplitText.new("text", "some string") }.to raise_exception
  end
  
  it "has a value equal to the text split across the regexp" do
    text = 'My text made of words'
    regex = /\s/
    expect(SplitText.new(text, regex).peek).to eq(%w[My text made of words])
  end
  
  context "when given a pattern with a match group" do  
    it "keeps pieces of the text matched by the match group" do
      text = <<EOS
1. Line 1
2. Line 2
3. Line 3
EOS
      regex = /^(\d)\. /    # one digit, as the match, followed by a period and a space
      text_minus_dot_space = ["1", "Line 1\n", "2", "Line 2\n", "3", "Line 3\n"]    
      expect(SplitText.new(text, regex).split).to eq(text_minus_dot_space)
    end
  end
  
  describe "#rejoin" do
    let(:delimiter) { '*' }
    let(:text) { "My text made of words" }
    let(:rejoined_text) { "My*text*made*of*words" }
    let(:splitter) { SplitText.new(text, /\s/) }

    it "rejoins split text with a given delimiter" do
      expect(splitter.rejoin(delimiter)).to eq(rejoined_text)
    end
    
    context "when given a second argument" do
      it "rejoins text, adding the second argument between matches" do
        splitter = SplitText.new("1:My 2:enumerated 3:text 4:made 5:of 6:words", /\s?(\d):/)
        expect(splitter.rejoin(" ", "*")).to eq("1*My 2*enumerated 3*text 4*made 5*of 6*words")
      end
    end
  end
end