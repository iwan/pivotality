module Pivotality

  class Piv
    attr_reader :requirements, :year, :imports, :limits, :operator_production, :competitor_production, :results
    REQ_TYPES = [:ene, :pot]

    def initialize(year, results: PivResults.new(skip_negative: false))
      @year = year
      @results = results

      @operator_name = {}
      @zone_name = {}

      @requirements = {ene: {}, pot: {}}  # { ene: {zone_id => values_array, ...}, pot: {zone_id => values_array, ...}}
      @imports = {}   # {zone_id => values_array}
      @limits = {}    # { to_zone_id => { from_zone_id => values_array, ... }, ...}
      @operator_production = {}    #  { operator_id => {zone_id => values_array, ...}, ...}
      @competitor_production = {}  #  { operator_id => {zone_id => values_array, ...}, ...}

      @zone_ids

      init_calculation
    end

    # Add Energy request ("Fabbisogno di energia") data,
    # as an hash {zone_id => values_array, ...}
    def add_energy_req(hash)
      @requirements[:ene].merge! hash
    end

    # Add Power request ("Fabbisogno di potenza") data,
    # as an hash {zone_id => values_array, ...}
    def add_power_req(hash)
      @requirements[:pot].merge! hash
    end

    # Add Imports from abroad data,
    # as an hash {zone_id => values_array, ...}
    def add_imports(hash)
      @imports.merge! hash
    end

    # Add limits of energy transport between zones data,
    # as an hash: { to_zone_id => {from_zone_id => values_array, ...}, ...}
    def add_limits(hash)
      @limits.merge! hash
    end

    # Add zone total production of the operator
    # pass the operator and an hash: {zone_id => values_array}
    def add_operator_production(operator_id, hash)
      @operator_production[operator_id]||={}
      @operator_production[operator_id].merge! hash
    end

    # Add zone total production of competitors of the operator
    # pass the operator and an hash: {zone_id => values_array}
    def add_competitors_production(operator_id, hash)
      @competitor_production[operator_id]||={}
      @competitor_production[operator_id].merge! hash
    end

    # Set the zone_id => zone_name pairs
    def set_zones_decode(hash)
      @zone_name = hash
    end

    # Get the zone name, given the zone id
    def zone_name(zone_id)
      @zone_name.fetch(zone_id, :undefined)
    end

    # Set the operator_id => operator_name pairs
    def set_operators_decode(hash)
      @operator_name = hash
    end

    # Get the operator name, given the operator id
    def operator_name(operator_id)
      @operator_name.fetch(operator_id, :undefined)
    end


    # Get the operator ids (extracted from previously given data)
    def operator_ids
      @operator_ids ||= extract_operator_ids
    end

    # Get the zone ids with non-zero values
    # indipendent and dependent of operator
    def extract_zone_ids(operator_id)
      z = non_zero_zone_ids
      z += @operator_production[operator_id].map{|zone_id, arr| arr.any?{|e| !e.zero?} ? zone_id : nil }.compact if @operator_production[operator_id]
      z += @competitor_production[operator_id].map{|zone_id, arr| arr.any?{|e| !e.zero?} ? zone_id : nil }.compact if @competitor_production[operator_id]
      z.uniq.sort
    end

    # Get the zone ids with non-zero values
    # indipendent of operator
    def non_zero_zone_ids
      @non_zero_zone_ids ||= extract_non_zero_zone_ids
    end



    # Sum the total production of an operator in the zone set
    # (zone_set is an array of zone ids)
    def sum_operator_production(operator_id, zone_set)
      zone_set.inject(Yarray.new(year)) { |sum, zone_id| sum + Yarray.new(year, arr: @operator_production[operator_id][zone_id]) }
    end

    # Initialize the results object
    def init_calculation
      @gross_zone_residual_demands ||= GrossZoneResidualDemands.new
    end


    # Calculates the 'gross' residual demand related to a single zone and
    # an operator.
    # req_type specify which energy request should be used for calculation
    #  (:ene for energy request and :pot for power request)
    def calc_zone_residual_demand(operator_id, req_type, zone_id)
      res = Yarray.new(year, arr: @requirements[req_type][zone_id])
      if @competitor_production[operator_id].has_key? zone_id # TODO: e se fossero più di una?
        res -= Yarray.new(year, arr: @competitor_production[operator_id][zone_id])
      end
      if @imports.has_key? zone_id # TODO: e se fossero più di una?
        res -= Yarray.new(year, arr: @imports[zone_id])
      end
      @limits.fetch(zone_id, {}).each_pair do |from_zone_id, v|
        res -= Yarray.new(year, arr: v)
      end
      res
    end


    # Calculates the residual demand of the given zone set
    def calc_zones_residual_demand(operator_id, req_type, zone_set)
      sum = Yarray.new(year)
      zone_set.each do |zone_id|
        d = @gross_zone_residual_demands.get(operator: operator_id, req_type: req_type, zone: zone_id)
        if d.nil?
          d = calc_zone_residual_demand(operator_id, req_type, zone_id)
          @gross_zone_residual_demands.add(operator: operator_id, req_type: req_type, zone: zone_id, yarray: d)
        end
        sum += d
        zone_set.select{|e| e!=zone_id}.each do |z_id|
          if @limits[zone_id] && @limits[zone_id][z_id]
            v = @limits[zone_id][z_id]
            sum += Yarray.new(year, arr: v)
          end
        end
      end
      sum
    end


    # Minimum between the residual and the op. production (in the given zones set)
    def net_residual_demand(operator_id, req_type, zone_set)
      zones_demand_res = calc_zones_residual_demand(operator_id, req_type, zone_set)
      Yarray.min(zones_demand_res, sum_operator_production(operator_id, zone_set))
    end


    # Run calculation for all operators, two req types, all zones
    # Options:
    # You can limit operators calculation using op_ids: [2,41]
    # You can limit req_type calculation using req_types: :ene
    def calculate(options={})
      options = { op_ids: operator_ids, req_types: REQ_TYPES }.merge(options)
      options[:req_type] = [options[:req_type]] if !options[:req_type].is_a? Array

      options[:op_ids].each do |operator_id|
        puts "operator: #{operator_id}"
        options[:req_types].each do |req_type|
          puts "  req_type: #{req_type}"
          zone_ids = extract_zone_ids(operator_id)
          get_subset_sizes(zone_ids).each do |subset_size|
            puts "    zone combination of #{subset_size}..."
            zone_ids.combination(subset_size).each do |zone_set|
              min = net_residual_demand(operator_id, req_type, zone_set)
              if block_given?
                yield(operator_id, req_type, zone_set, min)
              else
                @results.add(operator: operator_id, req_type: req_type, zone_set: zone_set, yarray: min)
              end
            end
          end
        end
      end
    end

    private


      # Get/calculate the zone ids with non-zero values
      # indipendent of operator
      def extract_non_zero_zone_ids
        z  = @requirements[:ene].map{|zone_id, arr| arr.any?{|e| !e.zero?} ? zone_id : nil }.compact
        z += @requirements[:pot].map{|zone_id, arr| arr.any?{|e| !e.zero?} ? zone_id : nil }.compact
        z += @imports.map{|zone_id, arr| arr.any?{|e| !e.zero?} ? zone_id : nil }.compact
        z += @limits.map{|to_zone_id, hash| hash.map{|from_zone_id, arr| arr.any?{|e| !e.zero?} ? to_zone_id : nil }}.flatten.compact
        z.uniq.sort
      end

      def extract_operator_ids
        z = @operator_production.keys
        z += @competitor_production.keys
        z.uniq.sort
      end

      def get_subset_sizes(zone_ids)
        1.upto(zone_ids.size).to_a
      end

  end
end
