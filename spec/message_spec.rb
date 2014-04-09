# last run: 4/9
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe HL7::Message do
  let(:text) do
    <<-END_TEXT
    0000000729MSH|^~\&|HLAB|GMH|||20140128041143||ORU^R01|20140128041143833|T|2.4
    PID|||00487630^^^ST01||Thompson^Richard^L||19641230|M|||^^^^^^^|||||||A2057219^^^^STARACC|291668118
    PV1||Null value detected|||||20535^Watson^David^D^^^MD^^^^^^STARPROV|||||||||||12|A2057219^^^^STARACC|||||||||||||||||
    ORC|RE
    OBR|||4A  A61302526|4ATRPOC^^OHHOREAP|||201110131555|||||||||A00384^Watson^David^D^^^MD^^STARPROV||||||201110131555|||F
    OBX|1|TX|APRESULT^.^LA01|2|  REPORT||||||F
    OBX|2|TX|APRESULT^.^LA01|3|  Name: GILLISPIE, MARODA          GGC-11-072157||||||F
    NTE|1||Testing performed by Grady Memorial Hospital, 561 West Central Ave., Delaware, Ohio, 43015, UNLESS otherwise noted.
    END_TEXT
  end  
  let(:message) { HL7::Message.new(text) }
  
  it "has a list of segments by name" do
    expect(message.segments).to be_a Hash
  end
  
  it "has a list of segments in order" do
    expect(message.lines).to be_a Array  
  end
  
  it "has an ID" do
    expect(message).to respond_to :id
  end
  
  it "has a type" do
    expect(message).to respond_to :type
  end
  
  it "allows access to its segments" do
    expect(message[:PID]).to be_a HL7::Segment
  end  
  
  context "multiple segments of the same type" do
    it "are stored together" do
      expect(message[:OBX]).to be_a HL7::OBX
    end
  end    

  describe "#header" do
    it "returns the header segment" do
      expect(message.header).to eq(message[:MSH])
    end
  end
  
  describe "#each_segment" do
    it "performs a task for each segment" do
      segments = []
      message.each_segment { |segment| segments << segment.type }
      expect(segments).to eq([:MSH, :PID, :PV1, :ORC, :OBR, :OBX, :NTE])
    end
  end
  
  describe "#details" do
    it "collects important details from the message" do
      expect(message.details).not_to be_empty
    end
  end
  
  describe "#segment_before" do
    it "lists the type of segment appearing before the given segment" do
      expect(message.segment_before(:PV1)).to eq(:PID)
    end
  end
  
  describe "#segment_after" do
    it "lists the type of segment appearing after the given segment" do
      expect(message.segment_after(:PV1)).to eq(:ORC)
    end    
  end
  
  it_behaves_like "HL7 object" do
    let(:object) { message }
  end
end