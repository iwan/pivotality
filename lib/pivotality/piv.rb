module Pivotality

  class Piv
    attr_reader :requirements, :year, :imports, :limits, :operator_production, :competitor_production, :results
    REQ_TYPES = [:ene, :pot]

    def initialize(year, results: PivResults.new(skip_negative: false))
      @year = year

      @operator_name = {}
      @zone_name = {}

      @requirements = {ene: {}, pot: {}}  # { ene: {zone_id => values, ...}, pot: {zone_id => values, ...}}
      @imports = {}   # {zone_id => values}
      @limits = {}    # { to_zone_id => { from_zone_id => values, ... }, ...}
      @operator_production = {}    #  { operator_id => {zone_id => values, ...}, ...}
      @competitor_production = {}  #  { operator_id => {zone_id => values, ...}, ...}

      @zone_ids
      init_calculation
    end

    # Add Energy request ("Fabbisogno di energia") data,
    # as an hash {zone_id => values, ...}
    def add_energy_req(hash)
      @requirements[:ene].merge! hash
    end

    # Add Power request ("Fabbisogno di potenza") data,
    # as an hash {zone_id => values, ...}
    def add_power_req(hash)
      @requirements[:pot].merge! hash
    end

    # Add Imports from abroad data,
    # as an hash {zone_id => values, ...}
    def add_imports(hash)
      @imports.merge! hash
    end

    # Add limits of energy transport between zones data,
    # as an hash: { to_zone_id => {from_zone_id => values, ...}, ...}
    def add_limits(hash)
      @limits.merge! hash
    end

    # Add zone total production of the operator
    # pass the operator and an hash: {zone_id => values}
    def add_operator_production(operator_id, hash)
      @operator_production[operator_id]||={}
      @operator_production[operator_id].merge! hash
    end

    # Add zone total production of competitors of the operator
    # pass the operator and an hash: {zone_id => values}
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

    # Get the zone ids (extracted from previously given data)
    def zone_ids
      @zone_ids ||= extract_zone_ids
    end

    # Get the operator ids (extracted from previously given data)
    def operator_ids
      @operator_ids ||= extract_operator_ids
    end


    # Sum the total production of an operator in the zone set
    # (zone_set is an array of zone ids)
    def sum_operator_production(operator_id, zone_set)
      zone_set.inject(Yarray.new(year)) { |sum, zone_id| sum + Yarray.new(year, arr: @operator_production[operator_id][zone_id]) }
    end

    # Initialize the results object
    def init_calculation
      @results ||= PivResults.new
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
    def calculate(operators: operator_ids, req_types: REQ_TYPES, subset_sizes: get_subset_sizes)
      operators.each do |operator_id|
        puts "operator: #{operator_id}"
        req_types.each do |req_type|
          puts "  req_type: #{req_type}"
          subset_sizes.each do |subset_size|
            puts "    zone combination of #{subset_size}..."
            zone_ids.combination(subset_size).each do |zone_set|
              min = net_residual_demand(operator_id, req_type, zone_set)
              @results.add(operator: operator_id, req_type: req_type, zone_set: zone_set, yarray: min)
            end
          end
        end
      end
    end

    private

      def extract_zone_ids
        z = @requirements[:ene].keys
        z += @requirements[:pot].keys
        z += @imports.keys
        z += @limits.keys
        z += @limits.values.map(&:keys).flatten
        z += @operator_production.values.map(&:keys).flatten
        z += @competitor_production.values.map(&:keys).flatten
        z.uniq.sort
      end

      def extract_operator_ids
        z = @operator_production.keys
        z += @competitor_production.keys
        z.uniq.sort
      end

      def get_subset_sizes
        1.upto(zone_ids.size).to_a
      end

  end
end
