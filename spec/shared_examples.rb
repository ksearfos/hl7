require 'spec_helper'

shared_examples "HL7 object" do
  context "when sent a message it does not recognize" do
    it "thows an exception" do
      expect { object.fakey_method }.to raise_exception 
    end
  end
  
  describe "#to_s" do
    it "converts it to a String" do
      object.to_s.should be_a String
    end
  end
  
  context "when given empty text" do
    it "throws an exception" do
      expect { klass.new(empty_input) }.to raise_exception
    end
  end
  
  context "when given non-HL7 text" do  
    it "throws an exception" do
      expect { klass.new(bad_input) }.to raise_exception
    end
  end  
end

shared_examples "private methods" do
  describe "#prepare_to_split" do
    it "replaces the pattern with '<SPLIT>' + match (or '') + '<MATCH>'" do
      actual = splitter.prepare_to_split(text, pattern)
      expect(actual).to eq(marked_text)
    end
  end

  describe "#split_across_pattern" do
    it "splits into 3 strings of the form: match (or '') + '<MATCH>' + something" do
      actual = splitter.split_across_pattern(marked_text)
      expect(actual).to eq(pattern_split_array)
    end  
  end  

  describe "#split_across_matches" do
    it "splits into 3 arrays, all of which have the form: [match (or ''), something]" do
      actual = splitter.split_across_matches(pattern_split_array)
      expect(actual).to eq(match_split_array)
    end
  end
end