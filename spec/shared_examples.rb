# last run: --
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
  
end    