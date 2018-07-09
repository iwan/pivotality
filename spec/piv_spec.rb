
RSpec.describe Piv do

  # it "does something useful" do
  #   piv = Pivotality::Piv.new
  #   ya = Yarray.new(2014, value: 3.0)
  #   hash = {1 => ya}
  #   piv.add_energy_req(hash)
  # end

  it "add energy requirements" do
    piv = Piv.new(2014)
    piv.add_energy_req(1 => [1,3,5])
    expect(piv.requirements[:ene].keys).to eq([1,3,5])
  end
end
