require 'spec_helper'
require 'playground/segment'

describe HL7::Segment do
  let(:segment) { HL7::Segment.new("TST|field1|field2|field3") }
  
  it "has a value" do
    expect(segment.value).not_to be_nil
  end
end