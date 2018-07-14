module Pivotality
  class PivResults
    attr_reader :res

    def initialize
      @arr = []
    end

    def add(operator:, req_type:, zone_set:, yarray:)
      @arr << {operator: operator, req_type: req_type, zone_set: zone_set.sort, yarray: yarray }
    end

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
