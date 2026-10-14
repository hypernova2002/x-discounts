require "rails_helper"

RSpec.describe MembershipSchemeResource do
  it "renders the scheme's plain fields" do
    scheme = create(:membership_scheme, name: "VIP Tiers")
    hash = described_class.new(scheme).to_h

    expect(hash["id"]).to eq(scheme.public_id)
    expect(hash["name"]).to eq("VIP Tiers")
  end

  it "omits membership_tiers by default" do
    scheme = create(:membership_scheme)
    expect(described_class.new(scheme).to_h).not_to have_key("tiers")
  end

  it "includes nested tiers (keyed 'tiers') when requested" do
    scheme = create(:membership_scheme)
    tier = create(:membership_tier, membership_scheme: scheme, name: "Gold")

    hash = described_class.new(scheme, params: { includes: ["membership_tiers"] }).to_h

    expect(hash["tiers"].size).to eq(1)
    expect(hash["tiers"].first["id"]).to eq(tier.public_id)
    expect(hash["tiers"].first["name"]).to eq("Gold")
  end
end
