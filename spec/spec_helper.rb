$LOAD_PATH.unshift File.expand_path("../..",__FILE__)

require 'rspec'
require 'HL7'
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

class TestFileHandler < HL7::FileHandler
  def initialize(file, count = 10000)
    super(file, count)
  end
  
  def get_records
    @records = next_set_of_messages
  end  
end

class TestMessage < HL7::Message
  def initialize(message_text)
    raise_error_if(message_text.empty?)
    @original_text = message_text
    @lines = []            # the list of segments, in order
    @segments = {}         # map of segments by type => { :SEG_TYPE => Segment object }
    @separators = {}       # the separators used by this HL7 message
    @type = :""
    break_into_segments    # updates @lines, @segments @separators
    set_message_type       # updates @type
    @id = "1234"
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
end