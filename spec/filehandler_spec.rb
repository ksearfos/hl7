$:.unshift File.dirname(__FILE__)
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

  it "has a file called #{@file}" do
    expect(@handler.file).to eq(@file)
  end
  
  context "when explicitly given a record limit" do
    it "has a limit of 2" do
      sized_handler = HL7::FileHandler.new(@file, 2)
      expect(sized_handler.instance_variable_get(:@limit)).to eq(2)
    end
  end
  
  context "when not given a record limit" do
    it "has a limit of 10000" do
      expect(@handler.instance_variable_get(:@limit)).to eq(10000)
    end
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
    it "creates Message objects from the text in @file" do
      expect(HL7::Message).to receive(:new).exactly(@handler.size).times
      @handler.do_for_all_messages{}
    end
    
    it "iterates over all messages contained in the file" do
      collection, char = "", '*'
      @handler.do_for_all_messages{ collection << char }
      expect(collection).to eq(char * @handler.size)
    end
    
    context "when given a code block" do
      it "executes the code for each Message object" do
        expect(HL7::Message).to receive(:new).at_least(:once)
        result = []
        @handler.do_for_all_messages { |message| result << message }
        expect(result.uniq).to eq(result)
      end
    end
    
    context "when not given a code block" do
      it "raises an error" do
        expect { @handler.do_for_all_objects }.to raise_exception
      end
    end
  end

  it_behaves_like "HL7 object" do
    let(:object) { @handler }
    let(:klass) { HL7::FileHandler }
    let(:bad_input) { "#{@data_directory}/non_hl7_file.txt" }
    let(:empty_input) { "#{@data_directory}/empty_file.txt" }
  end  
  
end    