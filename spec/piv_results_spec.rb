RSpec.describe PivResults do
  subject(:op){ 1 }
  subject(:size){ 24*30 }


  it "collect all results" do
    res = PivResults.new(skip_negative: false)
    res.set(operator: op, req_type: :ene, zone_set: [2], vector: Vector::Vector.new(size: size, initial_value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], vector: Vector::Vector.new(size: size, initial_value: -3.0))
    expect(res.arr.count).to eq(2)
  end

  it "collect all results on default initializer" do
    res = PivResults.new
    res.set(operator: op, req_type: :ene, zone_set: [2], vector: Vector::Vector.new(size: size, initial_value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], vector: Vector::Vector.new(size: size, initial_value: -3.0))
    expect(res.arr.count).to eq(1)
  end

  it "get correct yarray" do
    res = PivResults.new(skip_negative: false)
    res.set(operator: op, req_type: :ene, zone_set: [2], vector: Vector::Vector.new(size: size, initial_value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [1,3], vector: Vector::Vector.new(size: size, initial_value: -3.0))
    r = res.get(operator: op, req_type: :ene, zone_set: [3,1])
    expect(r.class).to eq(Vector::Vector)
    expect(r.size).to eq(24*30)
    # expect(r.year).to eq(year)
    expect(r.arr.first).to eq(-3)
    expect(r.arr.last).to eq(-3)
  end

  it "get nil on empty results" do
    res = PivResults.new
    res.set(operator: op, req_type: :ene, zone_set: [2], vector: Vector::Vector.new(size: size, initial_value: 4.0))
    r = res.get(operator: op, req_type: :ene, zone_set: [3,1])
    expect(r).to be_nil
  end

  it "collect only positive results" do
    res = PivResults.new(skip_negative: true)
    res.set(operator: op, req_type: :ene, zone_set: [2], vector: Vector::Vector.new(size: size, initial_value: 4.0))
    res.set(operator: op, req_type: :ene, zone_set: [3], vector: Vector::Vector.new(size: size, initial_value: -3.0))
    expect(res.arr.count).to eq(1)
  end
end
