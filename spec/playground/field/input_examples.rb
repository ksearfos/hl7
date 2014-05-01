shared_examples "specific values" do  
  describe "specific input:" do
    context "when given 'alligator'" do
      it "is 'alligator'" do
        field = HL7::Field.new("alligator")
        expect(field.value).to eq("alligator")
      end
    end

    context "when given 'crocodile'" do
      it "is 'crocodile'" do
        field = HL7::Field.new("crocodile")
        expect(field.value).to eq("crocodile")
      end
    end    
      
    context "when given an empty string" do
      it "is an empty string" do
        field = HL7::Field.new("")
        expect(field.value).to be_empty
      end
    end

    context "when given a Symbol" do
      it "raises an error" do
        expect { HL7::Field.new(:not_a_string) }.to raise_exception
      end
    end

    context "when given an Array containing Strings" do
      it "raises an error" do
        expect { HL7::Field.new(["a string"]) }.to raise_exception
      end
    end
  
    context "when given Nil" do
      it "raises an error" do
        expect { HL7::Field.new(nil) }.to raise_exception
      end
    end    
  end    
end