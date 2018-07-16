
RSpec.describe Piv do

  # it "does something useful" do
  #   piv = Pivotality::Piv.new
  #   ya = Yarray.new(2014, value: 3.0)
  #   hash = {1 => ya}
  #   piv.add_energy_req(hash)
  # end

  it "add energy requirement" do
    piv = Piv.new(2014)
    piv.add_energy_req(1 => [1,3,5])
    expect(piv.requirements[:ene].keys).to eq([1])
    expect(piv.requirements[:ene][1]).to eq([1,3,5])
  end

  it "add power requirement" do
    piv = Piv.new(2014)
    piv.add_power_req(7 => [9,3,5,7], 8 => [3,2,1])
    expect(piv.requirements[:pot][7]).to eq([9,3,5,7])
    expect(piv.requirements[:pot][8]).to eq([3,2,1])
  end

  it "add imports" do
    piv = Piv.new(2014)
    piv.add_imports(7 => [9,3,5,7], 8 => [3,2,1])
    expect(piv.imports[7]).to eq([9,3,5,7])
    expect(piv.imports[8]).to eq([3,2,1])
  end

  it "add limits" do
    piv = Piv.new(2014)
    piv.add_limits(7 => {8 => [3,2,1]}, 8 => {7 => [9,3,5,7]})
    expect(piv.limits.keys).to eq([7,8])
    expect(piv.limits[8][7]).to eq([9,3,5,7])
    expect(piv.limits[7][8]).to eq([3,2,1])
  end

  it "add operator production" do
    piv = Piv.new(2014)
    piv.add_operator_production(3, 7 => [9,3,5,7], 8 => [3,2,1])
    expect(piv.operator_production[3][7]).to eq([9,3,5,7])
    expect(piv.operator_production[3][8]).to eq([3,2,1])
  end

  it "add competitor production" do
    piv = Piv.new(2014)
    piv.add_competitors_production(3, 7 => [9,3,5,7], 8 => [3,2,1])
    expect(piv.competitor_production[3][7]).to eq([9,3,5,7])
    expect(piv.competitor_production[3][8]).to eq([3,2,1])
  end

  it "get zone ids" do
    piv = Piv.new(2014)
    piv.add_energy_req(1 => [1,3,5])
    piv.add_power_req(7 => [9,3,5,7], 8 => [3,2,1])
    piv.add_imports(2 => [9,3,5,7], 8 => [3,2,1])
    piv.add_limits(7 => {8 => [3,2,1]}, 8 => {7 => [9,3,5,7]})
    piv.add_operator_production(3, 3 => [9,3,5,7], 8 => [3,2,1])
    piv.add_competitors_production(3, 7 => [9,3,5,7], 5 => [3,2,1])
    expect(piv.zone_ids).to eq([1,2,3,5,7,8])
  end

  it "get operator ids" do
    piv = Piv.new(2014)
    piv.add_operator_production(3, 3 => [9,3,5,7], 8 => [3,2,1])
    piv.add_operator_production(4, 3 => [9,3,5,7], 8 => [3,2,1])
    piv.add_competitors_production(3, 7 => [9,3,5,7], 5 => [3,2,1])
    piv.add_competitors_production(5, 7 => [9,3,5,7], 5 => [3,2,1])
    expect(piv.operator_ids).to eq([3,4,5])
  end

  it "set zone decode" do
    piv = Piv.new(2014)
    piv.set_zones_decode(3 => "nord", 4 => "sici", 5 => "sud")
    expect(piv.zone_name(3)).to eq("nord")
    expect(piv.zone_name(1)).to eq(:undefined)
  end

  it "set zone decode" do
    piv = Piv.new(2014)
    piv.set_operators_decode(13 => "acme", 4 => "energy_acme")
    expect(piv.operator_name(13)).to eq("acme")
    expect(piv.operator_name(1)).to eq(:undefined)
  end


  context "calculate" do
    context "single zone residual" do
      subject(:op_id) { 50 }
      subject(:zone_id) { 1 }
      let(:piv) { Piv.new(2014) }

      it "has residual demand smaller than operator production" do
        piv.add_energy_req(zone_id => Array.new(8760, 100), 2 => Array.new(8760, 888))
        piv.add_imports(zone_id => Array.new(8760, 27), 2 => Array.new(8760, 44))
        piv.add_limits(zone_id => {2 => Array.new(8760, 15), 3 => Array.new(8760, 13)}, 3 => {2 => Array.new(8760, 34)})
        piv.add_operator_production(op_id, zone_id => Array.new(8760, 25), 2 => Array.new(8760, 78))
        piv.add_competitors_production(op_id, zone_id => Array.new(8760, 30), 2 => Array.new(8760, 98))

        res = piv.calc_zone_residual_demand(op_id, :ene, zone_id)
        min = Yarray.min(res, piv.sum_operator_production(op_id, [zone_id]))
        expect(min.any_negative?).to be(false)
        expect(min.any_positive?).to be(true)
        expect(min.arr[0]).to eq(15)
        expect(min.arr[-1]).to eq(15)
      end

      it "has residual demand bigger than operator production" do
        piv.add_energy_req(zone_id => Array.new(8760, 100), 2 => Array.new(8760, 888))
        piv.add_imports(zone_id => Array.new(8760, 27), 2 => Array.new(8760, 44))
        piv.add_limits(zone_id => {2 => Array.new(8760, 15), 3 => Array.new(8760, 13)}, 3 => {2 => Array.new(8760, 34)})
        piv.add_operator_production(op_id, zone_id => Array.new(8760, 8), 2 => Array.new(8760, 78))
        piv.add_competitors_production(op_id, zone_id => Array.new(8760, 30), 2 => Array.new(8760, 98))

        res = piv.calc_zone_residual_demand(op_id, :ene, zone_id)
        min = Yarray.min(res, piv.sum_operator_production(op_id, [zone_id]))
        expect(min.any_negative?).to be(false)
        expect(min.any_positive?).to be(true)
        expect(min.arr[0]).to eq(8)
        expect(min.arr[-1]).to eq(8)
      end

      it "has negative residual demand" do
        piv.add_energy_req(zone_id => Array.new(8760, 100), 2 => Array.new(8760, 888))
        piv.add_imports(zone_id => Array.new(8760, 27), 2 => Array.new(8760, 44))
        piv.add_limits(zone_id => {2 => Array.new(8760, 15), 3 => Array.new(8760, 13)}, 3 => {2 => Array.new(8760, 34)})
        piv.add_operator_production(op_id, zone_id => Array.new(8760, 8), 2 => Array.new(8760, 78))
        piv.add_competitors_production(op_id, zone_id => Array.new(8760, 55), 2 => Array.new(8760, 98))

        res = piv.calc_zone_residual_demand(op_id, :ene, zone_id)
        min = Yarray.min(res, piv.sum_operator_production(op_id, [zone_id]))
        expect(min.any_negative?).to be(true)
        expect(min.any_positive?).to be(false)
        expect(min.arr[0]).to eq(-10)
        expect(min.arr[-1]).to eq(-10)
      end

    end

    context "two zone residual" do
      subject(:op1) { 101 }
      subject(:op2) { 102 }
      subject(:z1) { 1 }
      subject(:z2) { 2 }
      subject(:z3) { 3 }
      subject(:req_type) { :ene }
      let(:piv) { Piv.new(2014) }
      let(:zone_set) { [z1, z2]}

      it "has residual demand smaller than operator production" do
        piv.add_energy_req(
          z1 => Array.new(8760, 100),
          z2 => Array.new(8760, 250))
        piv.add_imports(z1 => Array.new(8760, 27), z2 => Array.new(8760, 44))
        piv.add_limits(
          z1 => {z2 => Array.new(8760, 15), z3 => Array.new(8760, 13)},
          z2 => {z1 => Array.new(8760, 23), z3 => Array.new(8760, 117)},
          z3 => {z1 => Array.new(8760, 34), z2 => Array.new(8760, 34)})
        piv.add_operator_production(op1, z1 => Array.new(8760, 25), z2 => Array.new(8760, 78))
        piv.add_competitors_production(op1, z1 => Array.new(8760, 30), z2 => Array.new(8760, 98))

        gross_zone_residual_demand = piv.calc_zone_residual_demands(op1, req_type)
        # min = piv.net_residual_demand(gross_zone_residual_demand, zone_set, op1)
        min = piv.net_residual_demand(op1, req_type, zone_set)
        expect(min.any_negative?).to be(false)
        expect(min.any_positive?).to be(true)
        expect(min.arr[0]).to eq(21)
        expect(min.arr[-1]).to eq(21)
      end

      it "has residual demand bigger than operator production" do
        piv.add_energy_req(
          z1 => Array.new(8760, 100),
          z2 => Array.new(8760, 250))
        piv.add_imports(z1 => Array.new(8760, 27), z2 => Array.new(8760, 44))
        piv.add_limits(
          z1 => {z2 => Array.new(8760, 15), z3 => Array.new(8760, 13)},
          z2 => {z1 => Array.new(8760, 23), z3 => Array.new(8760, 17)},
          z3 => {z1 => Array.new(8760, 34), z2 => Array.new(8760, 34)})
        piv.add_operator_production(op1, z1 => Array.new(8760, 25), z2 => Array.new(8760, 78))
        piv.add_competitors_production(op1, z1 => Array.new(8760, 30), z2 => Array.new(8760, 98))

        gross_zone_residual_demand = piv.calc_zone_residual_demands(op1, req_type)
        # min = piv.net_residual_demand(gross_zone_residual_demand, zone_set, op1)
        min = piv.net_residual_demand(op1, req_type, zone_set)

        expect(min.any_negative?).to be(false)
        expect(min.any_positive?).to be(true)
        expect(min.arr[0]).to eq(103)
        expect(min.arr[-1]).to eq(103)
      end
    end
  end
end
