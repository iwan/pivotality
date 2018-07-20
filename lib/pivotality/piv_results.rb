module Pivotality
  class PivResults
    attr_reader :arr

    def initialize(skip_negative: false)
      @arr = []
      @skip_negative = skip_negative
    end

    def set(operator:, req_type:, zone_set:, yarray:)
      if !@skip_negative || yarray.any_positive?
          @arr << {operator: operator, req_type: req_type, zone_set: zone_set.sort, yarray: yarray }
      end
    end
    alias :add :set

    def get(operator:, req_type:, zone_set:)
      sub_arr = @arr.select{|e| e[:operator]==operator && e[:req_type]==req_type && e[:zone_set]==zone_set.sort}
      if sub_arr.size==1
        sub_arr.first[:yarray]
      else
        nil
      end
    end
  end
end
