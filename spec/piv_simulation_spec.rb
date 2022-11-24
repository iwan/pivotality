RSpec.describe Piv do
  context "3 zones, 2 operator simulation" do
    subject(:op1) { 101 }
    subject(:op2) { 102 }
    subject(:z1) { 1 }
    subject(:z2) { 2 }
    subject(:z3) { 3 }
    let(:piv) { Piv.new(results: PivResults.new(skip_negative: false)) }
    let(:zone_set) { [z1, z2]}

    def arr_8760(n)
      Array.new(8760, n)
    end

    it "works!" do
      piv.add_energy_req(
        z1 => arr_8760(100),
        z2 => arr_8760(150),
        z3 => arr_8760(95)
      )
      piv.add_power_req(
        z1 => arr_8760(120),
        z2 => arr_8760(160),
        z3 => arr_8760(125)
      )
      piv.add_imports(
        z1 => arr_8760(50),
        z2 => arr_8760(0),
        z3 => arr_8760(0)
      )
      piv.add_limits(
        z1 => {
          z2 => arr_8760(20),
          z3 => arr_8760(17)
        },
        z2 => {
          z1 => arr_8760(14),
          z3 => arr_8760(9)
        },
        z3 => {
          z1 => arr_8760(29),
          z2 => arr_8760(16)
        })
      piv.add_operator_production(op1,
        z1 => arr_8760(10),
        z2 => arr_8760(10),
        z3 => arr_8760(10)
      )
      piv.add_competitors_production(op1,
        z1 => arr_8760(40),
        z2 => arr_8760(120),
        z3 => arr_8760(75)
      )
      piv.add_operator_production(op2,
        z1 => arr_8760(20),
        z2 => arr_8760(10),
        z3 => arr_8760(30)
      )
      piv.add_competitors_production(op2,
        z1 => arr_8760(20),
        z2 => arr_8760(130),
        z3 => arr_8760(60)
      )

      piv.calculate

      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z1]).arr.first).to eq(-27)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z2]).arr.first).to eq(7)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z3]).arr.first).to eq(-25)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z1,z2]).arr.first).to eq(14)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z1,z3]).arr.first).to eq(-6)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z2,z3]).arr.first).to eq(7)
      expect(piv.results.get(operator: op1, req_type: :ene, zone_set: [z1,z2,z3]).arr.first).to eq(30)

      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z1]).arr.first).to eq(-7)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z2]).arr.first).to eq(10)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z3]).arr.first).to eq(5)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z1,z2]).arr.first).to eq(20)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z1,z3]).arr.first).to eq(20)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z2,z3]).arr.first).to eq(20)
      expect(piv.results.get(operator: op1, req_type: :pot, zone_set: [z1,z2,z3]).arr.first).to eq(30)

      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z1]).arr.first).to eq(-7)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z2]).arr.first).to eq(-3)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z3]).arr.first).to eq(-10)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z1,z2]).arr.first).to eq(24)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z1,z3]).arr.first).to eq(29)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z2,z3]).arr.first).to eq(12)
      expect(piv.results.get(operator: op2, req_type: :ene, zone_set: [z1,z2,z3]).arr.first).to eq(60)

      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z1]).arr.first).to eq(13)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z2]).arr.first).to eq(7)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z3]).arr.first).to eq(20)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z1,z2]).arr.first).to eq(30)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z1,z3]).arr.first).to eq(50)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z2,z3]).arr.first).to eq(40)
      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z1,z2,z3]).arr.first).to eq(60)

      expect(piv.results.get(operator: op2, req_type: :pot, zone_set: [z3,z2]).arr.first).to eq(40)
    end
  end


end
