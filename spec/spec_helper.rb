$LOAD_PATH.unshift File.expand_path("../..",__FILE__)

require 'rspec'
require 'HL7'
require 'shared_examples'
require 'stringio'

# data of various types
$str = "20535^Watson^David^D^^^MD^^^^^^STARPROV"
$name_str = "Watson^David^D^IV^Dr.^MD"
$name_str_as_name = "Dr. David D Watson IV, MD"
$sm_name_str = "Watson^David^^Jr.^"
$sm_name_str_as_name = "David Watson Jr."
$date_str = "20140128"
$date_str_as_date = "01/28/2014"
$time_str = "141143"
$time_str_as_12hr = "2:11:43 PM"
$time_str_as_24hr = "14:11:43"
$date_time_str = $date_str + $time_str

# field
delim = '^'
$field = HL7::Field.new($str)
$date_field = HL7::Field.new($date_str)
$time_field = HL7::Field.new($time_str)
$dt_field = HL7::Field.new($date_time_str)
$name_field = HL7::Field.new($name_str)
$sm_name_field = HL7::Field.new($sm_name_str)

# segment
$seg_str = "||04172769^^^ST01||Follin^Amy^C||19840402|F|||^^^^^^^|||||||1133632194^^^^STARACC|275823686"
$seg_str2 = "||14159265^^^ST01||Doe^John^^^Mr.||19561217|M|||^^^^^^^|||||||3289472383^^^^STARACC|48711289"
$pid_cl = HL7.typed_segment(:PID)
$pid_fields = HL7::PID_FIELDS
$segment = HL7::Segment.new($seg_str)
$seg_2_line = HL7::Segment.new( $seg_str + "\n" + $seg_str2 )
$pid = $pid_cl.new( "PID|" + $seg_str )

# message
$lab_str =<<LAB
0000000729MSH|^~\&|HLAB|GMH|||20140128041143||ORU^R01|20140128041143833|T|2.4
PID|||00487630^^^ST01||Thompson^Richard^L||19641230|M|||^^^^^^^|||||||A2057219^^^^STARACC|291668118
PV1||Null value detected|||||20535^Watson^David^D^^^MD^^^^^^STARPROV|||||||||||12|A2057219^^^^STARACC|||||||||||||||||
ORC|RE
OBR|||4A  A61302526|4ATRPOC^^OHHOREAP|||201110131555|||||||||A00384^Watson^David^D^^^MD^^STARPROV||||||201110131555|||F
NTE|1||Testing performed by Grady Memorial Hospital, 561 West Central Ave., Delaware, Ohio, 43015, UNLESS otherwise noted.
NTE|2
NTE|3||Indeterminate for MI: 0.08-0.09 ng/mL
NTE|4||Possible MI, recommend follow-up serial testing: 0.1-0.59 ng/mL
NTE|5||Suggestive for MI: 0.6-1.5 ng/mL ; Positive for MI: >1.5 ng/mL
LAB

$rad_str =<<RAD
MSH|^~\&|CENRAD|RMH|||20140226123258||ORU^R01||P|2.4
PID|||03102519^^^ST01||Smith^Kevin^W||195908020000|M|||^^^^^^^|||||||1112431307^^^^STARACC|294645000
PV1||Outpatient|^^||||15677^Hofmeister^Joseph^K^^^MD^^STARPROV^^^^STARPROV|15677^Hofmeister^Joseph^K^^^MD^^STARPROV^^^^STARPROV|^^^^^^^^STARPROV^^^^STARPROV||||||||15677^Hofmeister^Joseph^K^^^MD^^STARPROV^^^^STARPROV|12|1112431307|||||||||||||||||||||||||201105041208|201105042359
ORC|||||||||201105041353||||
OBR|1||H19406393|IMG2027^CT CHEST AND ABDOMEN WITH CONTRAST|||20110501353|||||||||15677^^^^^^^^STARPROV^^^^STARPROV||||||201105041500|||F|||||||21134^^^^^^^^STARPROV^^^^
OBX|1|TX|&GDT||Clinical Information: lung ca 162.9
OBX|2|TX|&GDT||HISTORY:  Lung carcinoma.
OBX|3|TX|&GDT|| 
OBX|4|TX|&GDT||CT OF THE CHEST AND ABDOMEN WITH CONTRAST 05/04/2011:
OBX|5|TX|&GDT|| 
OBX|6|TX|&GDT||TECHNIQUE:  3 mm sections were obtained from the thoracic inlet through the iliac crest following
OBX|7|TX|&GDT||administration of 100 ml of Omnipaque 350.  Coronal and sagittal reformatted images were obtained.
RAD

$lab_message = HL7::Message.new( $lab_str )
$rad_message = HL7::Message.new( $rad_str )

RSpec.configure do |c|
  c.fail_fast = true
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
