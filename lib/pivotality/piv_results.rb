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

    # Loop over arr elements
    def each
      @arr.each do |n|
        yield(n)
      end
    end

    # Get the operators list
    def operators
      @arr.map{|h| h[:operator]}.uniq
    end

    # Get the req_types available for an operator
    def req_types(operator)
      @arr.select{|num| h[:operator]==operator}.map{|h| h[:req_type]}.uniq
    end

  end
end
