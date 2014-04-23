$LOAD_PATH.unshift File.dirname(__FILE__)
require 'spec_helper'

describe TextSplitter do
  it "requires text" do
    expect { TextSplitter.new(/nontext/, //) }.to raise_exception  
  end
  
  it "requires a regexp to split across" do
    expect { TextSplitter.new("text", "some string") }.to raise_exception
  end
  
  it "has text equal to the text provided" do
    text = 'SOME TEXT'
    expect(TextSplitter.new(text, /\w/).text).to eq(text)
  end
  
  it "has text that's been split across the regexp" do
    text = 'My text made of words'
    regex = /\s/
    expect(TextSplitter.new(text, regex).split_text).to eq(%w[My text made of words])
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
      expect(TextSplitter.new(text, regex).split_text).to eq(text_minus_dot_space)
    end
  end
  
  describe "#rejoin" do
    let(:delimiter) { '*' }
    let(:text) { "My text made of words" }
    let(:rejoined_text) { "My*text*made*of*words" }
    let(:splitter) { TextSplitter.new(text, /\s/) }

    it "rejoins split text with a given delimiter" do
      expect(splitter.rejoin(delimiter)).to eq(rejoined_text)
    end
  end

end