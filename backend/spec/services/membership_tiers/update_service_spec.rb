require "rails_helper"

RSpec.describe MembershipTiers::UpdateService do
  let(:scheme) { create(:membership_scheme) }
  let(:tier) { create(:membership_tier, membership_scheme: scheme, name: "Silver", rank: 1, grace_period_days: 10) }

  it "updates only name when only name is sent" do
    request = MembershipTierUpdateRequest.new(name: "Gold")
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.name).to eq("Gold")
    expect(updated.rank).to eq(1)
    expect(updated.grace_period_days).to eq(10)
  end

  it "updates only rank when only rank is sent" do
    request = MembershipTierUpdateRequest.new(rank: 5)
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.rank).to eq(5)
    expect(updated.name).to eq("Silver")
  end

  it "updates only requirements_condition when only it is sent" do
    condition = { entity: "customer", key: "order_count", operator: "gte", value: 3 }
    request = MembershipTierUpdateRequest.new(requirements_condition: condition)
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.requirements_condition.to_h).to eq({ entity: "customer", key: "order_count", operator: "gte", value: 3 })
    expect(updated.name).to eq("Silver")
  end

  it "clears requirements_condition to an empty hash when explicitly set to nil" do
    tier.update(requirements_condition: { entity: "customer", key: "order_count", operator: "gte", value: 3 })
    request = MembershipTierUpdateRequest.new(requirements_condition: nil)
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.requirements_condition.to_h).to eq({})
  end

  it "updates only grace_period_days when only it is sent" do
    request = MembershipTierUpdateRequest.new(grace_period_days: 60)
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.grace_period_days).to eq(60)
    expect(updated.name).to eq("Silver")
  end

  it "leaves every field untouched when the request is empty" do
    request = MembershipTierUpdateRequest.new({})
    updated = described_class.new(tier: tier, request: request).call

    expect(updated.name).to eq("Silver")
    expect(updated.rank).to eq(1)
    expect(updated.grace_period_days).to eq(10)
  end

  it "raises a ValidationError when rank collides with another tier in the same scheme" do
    create(:membership_tier, membership_scheme: scheme, rank: 9)
    request = MembershipTierUpdateRequest.new(rank: 9)

    expect { described_class.new(tier: tier, request: request).call }.to raise_error(ValidationError)
  end
end
