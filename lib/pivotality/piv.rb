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


    def calculate
      @operator_production.each_pair do |op_id, zone_op_prod|
        # fabb energia
        [:ene, :pot].each do |req_type|

          1.upto(zones.size).each do |zone_set_size|
            zone_sets = zones.combination(zone_set_size)
            zone_sets.each do |zone_set|
              res = 0.0  # residuo
              prop = 0.0 # produzione operatore
              zone_set.each do |zone|
                res += fabb_data[tipo_fabb][zone.id]
                res -= operators_data[op.id][zone.id][:co]
                prop += operators_data[op.id][zone.id][:op]
                if limits_data[zone.id]
                  limits_data[zone.id].each_pair do |from_zone_id, dtum_obj|
                    res -= dtum_obj # !!! se le zone sono adiacenti...
                  end
                end
                res -= imports_data[zone_id] if imports_data[zone_id]
              end
              res = min(res, prop)

              if res>0
                # memorizza risultato...
                results[op.id][tipo_fabb][zone_set] = res
              end
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
