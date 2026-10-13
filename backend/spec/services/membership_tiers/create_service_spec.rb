require "rails_helper"

RSpec.describe MembershipTiers::CreateService do
  let(:scheme) { create(:membership_scheme) }

  it "builds a tier from name/rank/grace_period_days" do
    request = MembershipTierRequest.new(name: "Gold", rank: 2, grace_period_days: 30)
    tier = described_class.new(scheme: scheme, request: request).call

    expect(tier).to be_a(MembershipTier)
    expect(tier.name).to eq("Gold")
    expect(tier.rank).to eq(2)
    expect(tier.grace_period_days).to eq(30)
    expect(tier.membership_scheme_id).to eq(scheme.id)
  end

  it "defaults requirements_condition to an empty hash when not given" do
    request = MembershipTierRequest.new(name: "Gold", rank: 1)
    tier = described_class.new(scheme: scheme, request: request).call
    expect(tier.requirements_condition.to_h).to eq({})
  end

  it "stores a given requirements_condition" do
    condition = { entity: "customer", key: "total_spent", operator: "gte", value: 1000 }
    request = MembershipTierRequest.new(name: "Gold", rank: 1, requirements_condition: condition)
    tier = described_class.new(scheme: scheme, request: request).call
    expect(tier.requirements_condition.to_h).to eq({ "entity" => "customer", "key" => "total_spent", "operator" => "gte", "value" => 1000 })
  end

  it "raises a ValidationError when rank collides with an existing tier in the same scheme" do
    create(:membership_tier, membership_scheme: scheme, rank: 1)
    request = MembershipTierRequest.new(name: "Silver", rank: 1)

    expect { described_class.new(scheme: scheme, request: request).call }.to raise_error(ValidationError)
  end

  it "doesn't collide on rank across different schemes" do
    other_scheme = create(:membership_scheme)
    create(:membership_tier, membership_scheme: other_scheme, rank: 1)
    request = MembershipTierRequest.new(name: "Gold", rank: 1)

    expect { described_class.new(scheme: scheme, request: request).call }.not_to raise_error
  end
end
