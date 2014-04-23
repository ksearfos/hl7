$:.unshift File.dirname(__FILE__)
require 'Methods'
require 'Constants'
require 'FileHandler'
require 'Message'
require 'Segment'
# require 'TypedSegment'
# require 'Field'

module HL7
 
  class Exception < StandardError; end
  class NoFileError < HL7::Exception; end
  class BadFileError < HL7::Exception; end
  class InputError < HL7::Exception; end
  class BadTextError < HL7::Exception; end
  
  SEPARATOR_OFFSETS = { field: 0, component: 1, subcomp: 2, subsubcomp: 3, sub_subsubcomp: 4 }
  
  def self.get_separators(header_text, starting_index)
    separators = {}
    SEPARATOR_OFFSETS.each do |name,offset|
      index = starting_index + offset
      separators[name] = header_text[index]
    end
    separators
  end                               
  
end