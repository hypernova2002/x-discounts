require "rails_helper"

RSpec.describe MembershipTierResource do
  it "renders the tier's plain fields" do
    tier = create(:membership_tier, name: "Gold", rank: 2, grace_period_days: 30)
    hash = described_class.new(tier).to_h

    expect(hash["id"]).to eq(tier.public_id)
    expect(hash["name"]).to eq("Gold")
    expect(hash["rank"]).to eq(2)
    expect(hash["grace_period_days"]).to eq(30)
  end

  it "always renders requirements_condition as a plain hash and auto_assignable" do
    condition = { entity: "customer", key: "total_spent", operator: "gte", value: 1000 }
    tier = create(:membership_tier, requirements_condition: condition)
    hash = described_class.new(tier).to_h

    expect(hash["requirements_condition"]).to eq({ "entity" => "customer", "key" => "total_spent", "operator" => "gte", "value" => 1000 })
    expect(hash["auto_assignable"]).to eq(true)
  end

  it "omits membership_scheme by default" do
    tier = create(:membership_tier)
    expect(described_class.new(tier).to_h).not_to have_key("membership_scheme")
  end

  it "includes a minimal membership_scheme when requested" do
    scheme = create(:membership_scheme, name: "VIP Tiers")
    tier = create(:membership_tier, membership_scheme: scheme)

    hash = described_class.new(tier, params: { includes: ["membership_scheme"] }).to_h

    expect(hash["membership_scheme"]).to eq({ id: scheme.public_id, name: "VIP Tiers" })
  end
end
