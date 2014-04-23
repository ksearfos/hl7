$LOAD_PATH.unshift File.expand_path("../lib",__FILE__)

require 'HL7'
require 'shared_examples'
require 'rspec'
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

class TestSegment
  attr_reader :type
  
  def initialize(array)
    @type = array[0][0]
    @lines = array.transpose[1]
  end  

  def sending_application
    fields[2]
  end
  
  def message_control_id
    fields[9]
  end
  
  def field(index)
    ["#{@type}#{index}"]
  end
  
  def all_fields(index)
    field(index) * @lines.size
  end
  
  def show
    puts @type
  end

  private
  
  def fields
    @lines.first.split('|')
  end
end

class TestSplitter < SplitText
  SPLIT_INDICATOR = '<SPLIT>'
  MATCH_INDICATOR = '<MATCH>'
  
  def initialize
  end
  
  def prepare_to_split(text, pattern)
    super(text, pattern)
  end
  
  def split_across_pattern(text)
    super(text)
    return @value
  end

  def split_across_matches(value)
    @value = value
    super()
    return @value
  end
end  