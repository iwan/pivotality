RSpec.describe PivResults do
  subject(:year){ 2018 }
  subject(:op){ 1 }


  it "collect all results" do
    res = PivResults.new(skip_negative: false)
    res.set(operator: op, req_type: :ene, zone_set: [2], yarray: Yarray.new(year, value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], yarray: Yarray.new(year, value: -3.0))
    expect(res.arr.count).to eq(2)
  end

  it "collect all results on default initializer" do
    res = PivResults.new
    res.set(operator: op, req_type: :ene, zone_set: [2], yarray: Yarray.new(year, value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], yarray: Yarray.new(year, value: -3.0))
    expect(res.arr.count).to eq(2)
  end

  it "get correct yarray" do
    res = PivResults.new(skip_negative: false)
    res.set(operator: op, req_type: :ene, zone_set: [2], yarray: Yarray.new(year, value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [1,3], yarray: Yarray.new(year, value: -3.0))
    r = res.get(operator: op, req_type: :ene, zone_set: [3,1])
    expect(r.class).to eq(Yarray)
    expect(r.size).to eq(8760)
    expect(r.year).to eq(year)
    expect(r.arr.first).to eq(-3)
    expect(r.arr.last).to eq(-3)
  end

  it "get nil on empty results" do
    res = PivResults.new
    res.set(operator: op, req_type: :ene, zone_set: [2], yarray: Yarray.new(year, value: 4.0))
    r = res.get(operator: op, req_type: :ene, zone_set: [3,1])
    expect(r).to be_nil
  end

  it "collect only positive results" do
    res = PivResults.new(skip_negative: true)
    res.set(operator: op, req_type: :ene, zone_set: [2], yarray: Yarray.new(year, value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], yarray: Yarray.new(year, value: -3.0))
    expect(res.arr.count).to eq(1)
  end


end
