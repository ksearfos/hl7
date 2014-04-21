# last run: 4/10
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe HL7::FileHandler do
  before(:all) do
    @data_directory = "#{File.dirname(__FILE__)}/test_data"
    @file = "#{@data_directory}/text_input.txt"
  end
  
  before(:each) do
    HL7::Message.stub(:new) { |text| text }
    @handler = HL7::FileHandler.new(@file)
  end

  it "has a file" do
    expect(@handler.file).not_to be_empty
  end
  
  it "can access the messages contained in the file" do
    expect(@handler.respond_to?(:get_messages, true)).to be_true
  end

  context "when given a file that doesn't exist" do
    it "throws an exception" do
      file = "#{@data_directory}/file_that_doesn't_exist.txt"
      expect { HL7::FileHandler.new(file) }.to raise_exception
    end
  end
 
  context "when given a file in non-standard HL7 format" do
    it "parses the file like normal" do
      file = "#{@data_directory}/wonky_hl7_input.dat"
      expect { HL7::FileHandler.new(file) }.not_to raise_exception
    end
  end
   
  describe "#do_for_all_messages" do
    before(:each) do
      @size = 2
      @sized_handler = HL7::FileHandler.new(@file, @size)
    end
    
    it "executes command for every message" do
      collection = ""
      char = "*"
      @sized_handler.do_for_all_messages{ |_| collection << char }
      expect(collection).to eq(char * @sized_handler.size)
    end
  end

  it_behaves_like "HL7 object" do
    let(:object) { @handler }
    let(:klass) { HL7::FileHandler }
    let(:bad_input) { "#{@data_directory}/non_hl7_file.txt" }
    let(:empty_input) { "#{@data_directory}/empty_file.txt" }
  end  
  
end    