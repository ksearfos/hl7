# last run: 4/10
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe HL7::FileHandler do
  let(:test_data_directory) { "#{File.dirname(__FILE__)}/test_data" }
  let(:file) { "#{test_data_directory}/text_input.txt" }
  let(:handler) { TestFileHandler.new(file) }

  it "has a file" do
    expect(handler.file).not_to be_empty
  end
  
  it "has a list of messages" do
    expect(handler.records).to be_a Array
  end

  context "when given a file that doesn't exist" do
    let(:file) { "#{test_data_directory}/file_that_doesn't_exist.txt" }
    
    it "throws an exception" do
      expect { TestFileHandler.new(file) }.to raise_exception
    end
  end
 
  context "when given a file in non-standard format" do
    let(:file) { "#{test_data_directory}/dat_input.dat" }
    it "parses the file like normal" do
      expect { TestFileHandler.new(file) }.not_to raise_exception
    end
  end
   
  context "when given a big file" do
    let(:size) { 2 }
    let(:sized_handler) { TestFileHandler.new(file, size) }
    
    it "breaks the messages into manageable portions" do
      expect(sized_handler.size).to eq(size)
    end  
    
    it "performs tasks for all messages" do
      count = 0
      sized_handler.do_in_increments { |records| count += records.size }
      expect(count).to eq(handler.size)
    end
  end

  it_behaves_like "HL7 object" do
    let(:object) { handler }
    let(:klass) { TestFileHandler }
    let(:bad_input) { "#{test_data_directory}/non_hl7_file.txt" }
    let(:empty_input) { "#{test_data_directory}/empty_file.txt" }
  end  
  
end    