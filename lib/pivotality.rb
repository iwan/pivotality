require "pivotality/version"
require "pivotality/piv"
require "pivotality/piv_results"
require "pivotality/gross_zone_residual_demands"

require 'year_array'

include YearArray
include Pivotality

class YearArray::Yarray
  def to_s
    "start_time: #{start_time}, arr: [#{arr[0..6].join(', ')}, ..., #{arr.last}]"
  end
end
