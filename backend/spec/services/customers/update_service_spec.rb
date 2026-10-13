require "rails_helper"

RSpec.describe Customers::UpdateService do
  let(:project) { create(:project) }
  let(:scheme) { create(:membership_scheme, project: project) }
  let(:tier) { create(:membership_tier, membership_scheme: scheme, name: "Gold") }
  let(:customer) { create(:customer, project: project) }

  it "saves the customer without touching membership when membership_tier_id isn't in the request" do
    request = CustomerUpdateRequest.new({})

    described_class.new(customer: customer, request: request, membership_tier: nil).call

    expect(customer.membership_tier_id).to be_nil
    expect(customer.customer_activity_events_dataset).to be_empty
  end

  it "assigns a new tier via change_membership_tier!, recording a membership_started event" do
    request = CustomerUpdateRequest.new(membership_tier_id: tier.public_id)

    updated = described_class.new(customer: customer, request: request, membership_tier: tier).call

    expect(updated.membership_tier_id).to eq(tier.id)
    expect(updated.membership_tier_entered_at).not_to be_nil
    events = customer.customer_activity_events_dataset.all
    expect(events.map(&:type)).to eq(["membership_started"])
  end

  it "clears the tier via change_membership_tier! when membership_tier_id is explicitly null" do
    customer.change_membership_tier!(tier)
    request = CustomerUpdateRequest.new(membership_tier_id: nil)

    updated = described_class.new(customer: customer, request: request, membership_tier: nil).call

    expect(updated.membership_tier_id).to be_nil
    events = customer.customer_activity_events_dataset.order(:id).all
    expect(events.map(&:type)).to eq(%w[membership_started membership_ended])
  end

  it "doesn't call change_membership_tier! when membership_tier_id equals the customer's current tier (a no-op)" do
    customer.change_membership_tier!(tier)
    request = CustomerUpdateRequest.new(membership_tier_id: tier.public_id)

    described_class.new(customer: customer, request: request, membership_tier: tier).call

    events = customer.customer_activity_events_dataset.all
    expect(events.map(&:type)).to eq(["membership_started"])
  end

  it "raises a ValidationError on a model validation failure" do
    customer.date_of_birth = Date.today + 1
    request = CustomerUpdateRequest.new({})

    expect { described_class.new(customer: customer, request: request, membership_tier: nil).call }.to raise_error(ValidationError)
  end
end
