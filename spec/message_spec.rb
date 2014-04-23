$:.unshift File.dirname(__FILE__)
require 'spec_helper'

describe HL7::Message do
  before(:all) do
    @text = <<END_TEXT
MSH|^~\&|HLAB|GMH|||20140128041143||ORU^R01|20140128041143833|T|2.4
PID|||00487630^^^ST01||Thompson^Richard^L||19641230|M|||^^^^^^^|||||||A2057219^^^^STARACC|291668118
PV1||Null value detected|||||20535^Watson^David^D^^^MD^^^^^^STARPROV|||||||||||12|A2057219^^^^STARACC|||||||||||||||||
ORC|RE
OBR|||4A  A61302526|4ATRPOC^^OHHOREAP|||201110131555|||||||||A00384^Watson^David^D^^^MD^^STARPROV||||||201110131555|||F
OBX|1|TX|APRESULT^.^LA01|2|  REPORT||||||F
OBX|2|TX|APRESULT^.^LA01|3|  Name: GILLISPIE, MARODA          GGC-11-072157||||||F
NTE|1||Testing performed by Grady Memorial Hospital, 561 West Central Ave., Delaware, Ohio, 43015, UNLESS otherwise noted.
END_TEXT
  end 
  
  before(:each) do
    HL7::Segment.stub(:new) { |array| array[0][0] }   # should be the segment type
    HL7::Segment.stub(:sending_application) { 'HLAB' }
    @message = HL7::Message.new(@text)
  end
  
  it "has a list of segments by name" do
    expect(@message.segments.values).to eq(%w[MSH PID PV1 ORC OBR OBX NTE])
  end
  
  it "has a message type of lab" do
    expect(@message.type).to eq(:lab) 
  end
  
  it "has a list of field, component, and subcomponent delimiters" do
    separators = @message.instance_variable_get(:@separators)
    expected = { field:"|", component:"^", subcomp:"~", subsubcomp:"\\", sub_subsubcomp:"&" }
    expect(separators).to eq(expected)
  end
  
  describe "#[]" do
    it "allows access to its segments" do
      expect(@message[:PID]).to be_a HL7::Segment
    end
    
    it "retrieves the segment of the given type" do
      expect(@message[:PID]).to eq('PID')    
    end
  end
  
  describe "#header" do
    it "returns the header segment" do
      expect(@message.header).to eq(message[:MSH])
    end
  end
  
  describe "#id" do
    it "returns the message ID" do
      expect(@message.id).to eq("20140128041143833") 
    end
  end
  
  describe "#each" do
    it "performs a task for each segment" do
      segments = []
      @message.each { |segment| segments << "#{segment}!" }
      expect(segments).to eq(%[MSH! PID! PV1! ORC! OBR! OBX! NTE!])
    end
  end
  
  describe "#view_segments" do
    it "displays the segments, neatly formatted" do
      HL7::Segment.stub(:show) { "peek-a-boo!" }      
      printed = capture_stdout { @message.view_segments }
      expect(printed).not_to be_empty
    end
  end
  
  describe "#all_fields" do
    it "returns the values of the field, in a list" do
      expect(@message.all_fields("orc1")).to be_a Array
    end
    
    it "gets the field value for each line of the segment" do
      expect(@message.all_fields("obx1").size).to eq(["1", "2"])
    end
    
    it "correctly identifies the segment and field based on the given text" do
      expect(@message.all_fields("nte3")).to eq(message[:NTE][3])
    end
  end
  
  describe "#verify_segment_order" do
    context "when the first segment type occurs before the second type" do
      it "is true" do
        expect(@message.verify_segment_order("pid", "obr")).to be_true
      end    
    end
    
    context "when the first segment type occurs after the second type" do
      it "is false" do
        expect(@message.verify_segment_order("obx", "msh")).to be_false
      end    
    end
    
    context "when given the same segment" do
      it "is false" do
        expect(@message.verify_segment_order("obx", "obx")).to be_false
      end    
    end
  end
  
  it_behaves_like "HL7 object" do
    let(:object) { @message }
    let(:klass) { HL7::Message }
    let(:bad_input) { "this is just a random sentence\n we can add MSH|but it will not help" }
    let(:empty_input) { "" }
  end  
end