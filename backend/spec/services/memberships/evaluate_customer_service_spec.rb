require "rails_helper"

RSpec.describe Memberships::EvaluateCustomerService do
  let(:scheme) { create(:membership_scheme) }
  let(:always_qualifies) { { entity: "customer", key: "order_count", operator: "gte", value: 0 } }
  let(:customer) { create(:customer, project: scheme.project) }

  it "promotes an unassigned customer into a qualifying tier and records membership_started" do
    tier = create(:membership_tier, membership_scheme: scheme, rank: 1, requirements_condition: always_qualifies)

    described_class.new(customer: customer).call

    events = customer.customer_activity_events_dataset.all
    expect(events.map(&:type)).to eq(["membership_started"])
    expect(events.first.payload).to eq("tier_name" => tier.name, "scheme_name" => scheme.name)
    expect(customer.reload.membership_tier_id).to eq(tier.id)
  end

  it "records membership_ended (old tier) and membership_started (new tier) on a promotion" do
    low = create(:membership_tier, membership_scheme: scheme, rank: 1, requirements_condition: always_qualifies)
    described_class.new(customer: customer).call

    high = create(:membership_tier, membership_scheme: scheme, rank: 2, requirements_condition: always_qualifies)
    described_class.new(customer: customer.reload).call

    events = customer.customer_activity_events_dataset.order(:id).all
    expect(events.map(&:type)).to eq(%w[membership_started membership_ended membership_started])
    expect(events.last(2).map { |e| e.payload["tier_name"] }).to eq([low.name, high.name])
  end
end
