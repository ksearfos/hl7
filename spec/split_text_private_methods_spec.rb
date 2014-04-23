$:.unshift File.dirname(__FILE__)
require 'spec_helper'
require 'shared_examples'

describe "SplitText" do
  context "when there is no match group" do
    include_examples "private methods" do
      let(:splitter) { TestSplitter.new }
      let(:text) { "abc def ghi" }
      let(:pattern) { /\s/ }      
      let(:marked_text) { "abc<SPLIT><MATCH>def<SPLIT><MATCH>ghi" } 
      let(:pattern_split_array) { ["<MATCH>abc", "<MATCH>def", "<MATCH>ghi"] }
      let(:match_split_array) { [["", "abc"], ["", "def"], ["", "ghi"]] }  
    end
  end
  
  context "when there is a match group" do
    include_examples "private methods" do
      let(:splitter) { TestSplitter.new }
      let(:text) { "1:abc 2:def 3:ghi" }
      let(:pattern) { /\s?(\d):/ }      
      let(:marked_text) { "<SPLIT>1<MATCH>abc<SPLIT>2<MATCH>def<SPLIT>3<MATCH>ghi" } 
      let(:pattern_split_array) { ["1<MATCH>abc", "2<MATCH>def", "3<MATCH>ghi"] }
      let(:match_split_array) { [["1", "abc"], ["2", "def"], ["3", "ghi"]] }  
    end
  end  
end