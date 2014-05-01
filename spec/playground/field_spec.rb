require 'spec_helper'
require 'playground/field'
require 'playground/field/input_examples'

describe HL7::Field do
  let(:field) { HL7::Field.new("some string") }
  
  it "has a value" do
    expect(field.value).not_to be_nil
  end
  
  describe "@value" do
    context "when initialized with a string" do
      it "is that string" do
        expect(field.value).to eq("some string")
      end
    end
    
    context "when initialized with a non-string" do
      it "raises an error" do
        expect { HL7::Field.new([]) }.to raise_exception
      end
    end
    
    context "when initialized with nothing at all" do
      it "raises an error" do
        expect { HL7::Field.new() }.to raise_exception      
      end
    end
    
    include_examples "specific values"
  end
  
  it "has a list of components" do
    expect(field.components).to be_a Array
  end
  
  describe "@components" do
    context "when value does not contain the component delimiter" do
      it "has only one element" do
        expect(field.components.size).to eq(1)
      end
      
      it "holds the entire value" do
        expect(field.components).to eq(["some string"])
      end
    end
    
    context "when value contains the component delimiter" do
      let(:field) { HL7::Field.new("two^components") }  # ^ is delimiter by default
      
      it "has multiple elements" do
        expect(field.components.size).to be > 1
      end
      
      it "has elements equal to the text separated by the delimiter" do
        expect(field.components).to eq(["two", "components"])
      end
      
      context "when the component delimiter is not the default" do
        it "has elements equal to the text separated by the delimiter" do
          field = HL7::Field.new("two*components", '*')
          expect(field.components).to eq(["two", "components"])
        end
      end
    end    
  end
  
  it "allows access to individual components" do
    field = HL7::Field.new("one^two^three")
    expect(field).to respond_to(:[])
  end
  
  describe "#[]" do
    let(:field) { HL7::Field.new("one^two^buckle^my^shoe") }
    
    it "accesses the components by index" do
      expect(field[0]).to be_a String
    end
    
    context "when given a positive index" do
      it "accesses the component at index - 1", :detail => "because the HL7 format starts at 1" do
        expect(field[1]).to eq("one")
      end
    end
    
    context "when given a negative index" do
      it "raises an exception", :detail => "because HL7 doesn't understand negative component counts" do
        expect { field[-2] }.to raise_exception
      end
    end
    
    context "when given an index greater than the number of compnents" do
      it "returns nil" do
        expect(field[10]).to be_nil
      end
    end
  end
  
  it "can be formatted for certain value types" do
    expect(field).to respond_to(:return_as)
  end
  
  describe "#return_as" do
    context "when the field represents a date" do
      it "returns the value as 'MM/DD/YYYY'" do
        date_field = HL7::Field.new("20131104")  # Nov. 4, 2013
        expect(date_field.return_as(:date)).to eq("11/4/2013")
      end
    end
    
    context "when the field represents a time" do
      it "returns the value as 'HH:MM'" do
        time_field = HL7::Field.new("2342")  # 11:42 PM
        expect(time_field.return_as(:time)).to eq("23:42")
      end  
      
      context "when the seconds is included" do
        it "returns the value as 'HH:MM:SS'" do
          time_field = HL7::Field.new("110645")  # 11:06 AM (and 45 seconds)
          expect(time_field.return_as(:time)).to eq("11:06:45")
        end
      end 
    end
    
    context "when the field represents a name" do
      it "returns the value as 'Prefix First MI Last, Suffix Degree'" do
        name_field = HL7::Field.new("Smith^John^J^III^Mr^Ph.D")
        expect(name_field.return_as(:name)).to eq("Mr John J Smith III, Ph.D")
      end

      context "when the first component is the user's ID" do
        it "removes the ID and formats the remaining text" do
          name_field = HL7::Field.new("123456^Doe^Jane^Marie^^Dr^")
          expect(name_field.return_as(:name)).to eq("Dr Jane Marie Doe")
        end        
      end      
    end
    
    context "when the field represents a date and a time" do
      it "returns the value as 'MM/DD/YYYY HH:MM(:SS)'" do
        datetime = HL7::Field.new("198409261104")
        expect(datetime.return_as(:datetime)).to eq("9/26/1984 11:04")
      end
    end
  end
end