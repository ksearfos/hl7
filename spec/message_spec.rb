# last run: 4/9
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe HL7::Message do
  let(:text) do
    <<-END_TEXT
    012345MSH|^~\&|HLAB|GMH|||20140128041143||ORU^R01|20140128041143833|T|2.4
    PID|||00487630^^^ST01||Thompson^Richard^L||19641230|M|||^^^^^^^|||||||A2057219^^^^STARACC|291668118
    PV1||Null value detected|||||20535^Watson^David^D^^^MD^^^^^^STARPROV|||||||||||12|A2057219^^^^STARACC|||||||||||||||||
    ORC|RE
    OBR|||4A  A61302526|4ATRPOC^^OHHOREAP|||201110131555|||||||||A00384^Watson^David^D^^^MD^^STARPROV||||||201110131555|||F
    OBX|1|TX|APRESULT^.^LA01|2|  REPORT||||||F
    OBX|2|TX|APRESULT^.^LA01|3|  Name: GILLISPIE, MARODA          GGC-11-072157||||||F
    NTE|1||Testing performed by Grady Memorial Hospital, 561 West Central Ave., Delaware, Ohio, 43015, UNLESS otherwise noted.
    END_TEXT
  end 
  let(:message) { TestMessage.new(text) }
  
  it "has a list of segments by name" do
    expect(message.segments).to be_a Hash
  end
  
  it "has a list of segments in order" do
    expect(message.segments_in_order).to be_a Array  
  end
  
  it "has an ID" do
    expect(message).to respond_to :id
  end
  
  it "has a type" do
    expect(message).to respond_to :type
  end
  
  it "allows access to its segments" do
    expect(message[:PID]).not_to be_nil
  end  
  
  context "multiple segments of the same type" do
    it "are stored together" do
      expect(message[:OBX].size).to be > 1
    end
  end    

  describe "#header" do
    it "returns the header segment" do
      expect(message.header).to eq(message[:MSH])
    end
  end
  
  describe "#each_segment" do
    it "performs a task for each segment" do
      test_segment = double("segment")
      test_segment.stub(:type) { "ABC" }
      segments = []
      message.each_segment { |segment| segments << test_segment.type }
      expect(segments).to include("ABC")
    end
  end
  
  describe "#details" do
    context "when no specific details are requested" do
      it "collects all important details from the message" do
        expect(message.details).not_to be_empty
      end
    end
    
    context "when specific details are requested" do
      it "collects only the desired details" do
        expect(message.details(:id, :pt_name).size).to eq(2)
      end
    end
  end
  
  describe "#view_segments" do
    it "displays the segments, neatly formatted" do
      class String; def show; puts self; end; end    # view_segments calls Segment#show, or in this case, Array#show
      
      printed = capture_stdout { message.view_segments }
      expect(printed).not_to be_empty
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
    let(:klass) { TestMessage }
    let(:bad_input) { "this is just a random sentence\n we can add MSH|but it will not help" }
    let(:empty_input) { "" }
  end  
end