module Pivotality

  class Piv
    attr_reader :requirements, :year, :imports, :limits, :operator_production, :competitor_production
    def initialize(year)
      @year = year

      @operator_name = {}
      @zone_name = {}

      @requirements = {ene: {}, pot: {}}  # { ene: {zone_id => values, ...}, pot: {zone_id => values, ...}}
      @imports = {}   # {zone_id => values}
      @limits = {}    # { to_zone_id => { from_zone_id => values, ... }, ...}
      @operator_production = {}    #  { operator_id => {zone_id => values, ...}, ...}
      @competitor_production = {}  #  { operator_id => {zone_id => values, ...}, ...}

      @zone_ids
    end

    # hash = {zone_id => values}
    def add_energy_req(hash)
      @requirements[:ene] = hash
    end

    # hash = {zone_id => values}
    def add_power_req(hash)
      @requirements[:pot] = hash
    end

    # hash: {zone_id => values}
    def add_imports(hash)
      @imports = hash
    end

    # hash: { to_zone_id => { from_zone_id => values, ... }}
    def add_limits(hash)
      @limits = hash
    end

    # hash = {zone_id => values}
    def add_operator_production(operator_id, hash)
      @operator_production[operator_id] = hash
    end

    # hash = {zone_id => values}
    def add_competitor_production(operator_id, hash)
      @competitor_production[operator_id] = hash
    end

    def set_zones_decode(hash)
      @zone_name = hash
    end

    def zone_name(n)
      @zone_name.fetch(n, :undefined)
    end

    def set_operators_decode(hash)
      @operator_name = hash
    end

    def operator_name(n)
      @operator_name.fetch(n, :undefined)
    end

    def zone_ids
      @zone_ids ||= extract_zone_ids
    end

    def operator_ids
      @operator_ids ||= extract_operator_ids
    end



    def calc_single_zone_residuals(operator_id, req_type)
      puts "operator_id: #{operator_id.inspect}"
      puts "req_type:    #{req_type.inspect}"
      puts "zone_ids:    #{zone_ids.inspect}"
      # @zone_residual_demand = ZoneResidualDemand.new
      single_zone_residual = {}
      zone_ids.each do |zone_id|
        single_zone_residual[zone_id] = calc_single_zone_residual(operator_id, req_type, zone_id)
        # single_zone_residual[zone_id] = res # Yarray.min(res, Yarray.new(year, arr: v)
      end
      single_zone_residual
    end


    def calc_single_zone_residual(operator_id, req_type, zone_id)
      puts zone_id
      res = Yarray.new(year, arr: @requirements[:ene][zone_id])
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

    # zone_set is an array of zone ids
    def sum_operator_production(operator_id, zone_set)
      zone_set.inject(Yarray.new(year)) { |sum, zone_id| sum + Yarray.new(year, arr: @operator_production[operator_id][zone_id]) }
    end

    class Result
      attr_reader :res
      def initialize
        @res = {}
      end

      def add_residual_demand(operator_id, req_type, zone_set, res)
        @res[[operator_id, req_type, zone_set]] = res.any_positive? ? res : :negative
      end
    end

    def init_calculation
      @result = Result.new
    end

    def subset_sizes
      1.upto(zone_ids.size).to_a
    end

    def calc_zones_residual(single_zone_residual, zone_set)
      sum = Yarray.new(year)
      zone_set.each do |zone_id|
        sum += single_zone_residual[zone_id]
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
    def net_residual_demand(single_zone_residual, zone_set, op_id)
      zones_demand_res = calc_zones_residual(single_zone_residual, zone_set)
      # Minimum between the residual and the op. production (in the given zones set)
      Yarray.min(zones_demand_res, sum_operator_production(op_id, zone_set))
    end

    def calculate
      init_calculation
      @operator_ids.each do |op_id|
        [:ene, :pot].each do |req_type|
          single_zone_residual = calc_single_zone_residuals(op_id, req_type)
          subset_sizes.each do |subset_size|
            puts "zone combination of #{subset_size}..."
            zone_ids.combination(subset_size).each do |zone_set|
              min = net_residual_demand(single_zone_residual, zone_set, op_id)
              @result.add_residual_demand(op_id, req_type, zone_set, min)
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
  end
end
