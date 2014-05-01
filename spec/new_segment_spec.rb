require 'spec_helper'

describe HL7::Segment do
  let(:child_class) { HL7::PID }
  let(:text) do
    %w(OBX|1|NM|NA^Sodium|1|128|mmol/L|135-145|L|||F
       OBX|2|NM|K+^Potassium|1|5.0|mmol/L|3.5-5.1|N|||F
       OBX|3|NM|CL^Chloride|1|92|mmol/L|98-108|L|||F)
  end
  let(:message) { HL7::Segment.new($separators, :OBX, *text) }
  
  it "has a list of children" do
    expect(message.children).to be_a Array
  end
  
  it "allows access to its child segments" do
    expect(segment.children.first).to be_a child_class
  end
  
  describe "#[]" do
    context "given an Integer" do
      it "finds the value of the field with the given index" do
        expect(segment[3]).to eq("NA^Sodium")
      end
    end
    
    context "given a string or symbol" do
      it "finds the value of the field with the given name" do
        expect(segment[:component_id]).to eq("NA^Sodium")
      end
    end
  end  
  
  describe "#field" do
    it "returns the Field object specified" do
      expect(segment.field(1)).to be_a HL7::Field
    end
  end
  
  describe "#all_fields" do
    let(:all_fields) { segment.all_fields(3) }
    
    it "returns a list of values" do
      expect(all_fields).to be_a Array
    end
    
    it "returns the value of the field for each child" do
      expect(all_fields.size).to eq(segments.children.size)
    end
  end
  
  describe "#each" do
    it "executes code for each child segment" do
      #
    end
  end
  
  describe "#view_fields" do
    it "displays all fields, neatly formatted" do
      segment_text =<<END_TEXT
1:1, 2:NM, 3:NA^Sodium, 4:1, 5:128, 6:mmol/L, 7:135-145, 8:L, 9: , 10: , 11:F
1:2, 2:NM, 3:K+^Potassium, 4:1, 5:5.0, 6:mmol/L, 7:3.5-5.1, 8:L, 9: , 10: , 11:F
1:3, 2:NM, 3:CL^Chloride, 4:1, 5:92, 6:mmol/L, 7:98-108, 8:L, 9: , 10: , 11:F
END_TEXT
      printed_text = capture_stdout { segment.view_fields }
      expect(printed_text).to eq(segment_text)
    end
  end
  
  it_behaves_like "HL7 object" do
    let(:object) { segment }
    let(:klass) { HL7::Segment }
    let(:bad_input) { "this is just a random sentence\n we can add MSH|but it will not help" }
    let(:empty_input) { "" }
  end  
end