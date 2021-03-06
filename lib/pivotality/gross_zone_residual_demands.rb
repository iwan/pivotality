module Pivotality
  class GrossZoneResidualDemands
    attr_reader :arr

    def initialize
      @arr = []
    end

    def add(operator:, req_type:, zone:, yarray:)
      @arr << {operator: operator, req_type: req_type, zone: zone, yarray: yarray }
      yarray
    end

    def get(operator:, req_type:, zone:)
      sub_arr = @arr.select{|e| e[:operator]==operator && e[:req_type]==req_type && e[:zone]==zone}
      if sub_arr.size==1
        sub_arr.first[:yarray]
      else
        nil
      end
    end
  end
end
