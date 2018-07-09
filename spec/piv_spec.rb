
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
    piv.add_competitor_production(3, 7 => [9,3,5,7], 8 => [3,2,1])
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
    piv.add_competitor_production(3, 7 => [9,3,5,7], 5 => [3,2,1])
    expect(piv.zone_ids).to eq([1,2,3,5,7,8])
  end

  it "get operator ids" do
    piv = Piv.new(2014)
    piv.add_operator_production(3, 3 => [9,3,5,7], 8 => [3,2,1])
    piv.add_operator_production(4, 3 => [9,3,5,7], 8 => [3,2,1])
    piv.add_competitor_production(3, 7 => [9,3,5,7], 5 => [3,2,1])
    piv.add_competitor_production(5, 7 => [9,3,5,7], 5 => [3,2,1])
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

end
