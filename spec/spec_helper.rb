$LOAD_PATH.unshift File.expand_path("../..",__FILE__)

require 'rspec'
require 'HL7'
require 'TextSplitter'
require 'shared_examples'
require 'stringio'

# data of various types
# $str = "20535^Watson^David^D^^^MD^^^^^^STARPROV"
# $name_str = "Watson^David^D^IV^Dr.^MD"
# $name_str_as_name = "Dr. David D Watson IV, MD"
# $sm_name_str = "Watson^David^^Jr.^"
# $sm_name_str_as_name = "David Watson Jr."
# $date_str = "20140128"
# $date_str_as_date = "01/28/2014"
# $time_str = "141143"
# $time_str_as_12hr = "2:11:43 PM"
# $time_str_as_24hr = "14:11:43"
# $date_time_str = $date_str + $time_str

# field
# delim = '^'
# $field = HL7::Field.new($str)
# $date_field = HL7::Field.new($date_str)
# $time_field = HL7::Field.new($time_str)
# $dt_field = HL7::Field.new($date_time_str)
# $name_field = HL7::Field.new($name_str)
# $sm_name_field = HL7::Field.new($sm_name_str)

# segment
# $seg_str = "||04172769^^^ST01||Follin^Amy^C||19840402|F|||^^^^^^^|||||||1133632194^^^^STARACC|275823686"
# $seg_str2 = "||14159265^^^ST01||Doe^John^^^Mr.||19561217|M|||^^^^^^^|||||||3289472383^^^^STARACC|48711289"
# $pid_cl = HL7.typed_segment(:PID)
# $pid_fields = HL7::PID_FIELDS
# $segment = HL7::Segment.new($seg_str)
# $seg_2_line = HL7::Segment.new( $seg_str + "\n" + $seg_str2 )
# $pid = $pid_cl.new( "PID|" + $seg_str )

$separators = { field:"|", comp:"^", subcomp:"~", subsub:"\\", sub_subsub:"&" }

RSpec.configure do |c|
  c.fail_fast = true
  c.formatter = :documentation
end

# takes the code expected to print to stdout
# returns string that was written
# I copied this from one of the nice people on StackOverflow, see http://stackoverflow.com/questions/16507067/testing-stdout-output-in-rspec
def capture_stdout(&printing_action)
  old = $stdout
  $stdout = next_stdout = StringIO.new
  printing_action.call
  next_stdout.string
ensure
  $stdout = old
end

class TestMessage < HL7::Message
  def initialize(message_text)
    super
  end  

  def details(*all)
    info_types = all.empty? ? %w(id type date pt_name pt_acct dob proc_name proc_date visit) : all
    all_details = {}
    info_types.each do |info_type|
      key = info_type.upcase.to_sym     # turn "id" into :ID, for example
      all_details[key] = key
    end
      
    all_details
  end
    
  def add_segment(type, lines)
    @segments[type] = lines 
  end
  
  def break_into_segments    
    @segments_in_order = [:MSH, :PID, :PV1, :ORC, :OBR, :OBX, :NTE]
    @segments[:MSH] = "012345MSH|^~\&|HLAB|GMH|||20140128041143||ORU^R01|20140128041143833|T|2.4"
    @segments[:PID] = "PID|||00487630^^^ST01||Thompson^Richard^L||19641230|M|||^^^^^^^|||||||A2057219^^^^STARACC|291668118"
    @segments[:PV1] = "PV1||Null value detected|||||20535^Watson^David^D^^^MD^^^^^^STARPROV||"
    @segments[:ORC] = "ORC|RE"
    @segments[:OBR] = "OBR|||4A  A61302526|4ATRPOC^^OHHOREAP|||201110131555||||"
    @segments[:OBX] = ["OBX|1|TX|APRESULT^.^LA01|2|  REPORT||||||F"]
    @segments[:OBX] << "OBX|2|TX|APRESULT^.^LA01|3|  Name: GILLISPIE, MARODA          GGC-11-072157||||||F"
  end
end