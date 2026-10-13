require "rails_helper"

RSpec.describe Customers::DuplicateService do
  let(:project) { create(:project) }
  let(:scheme) { create(:membership_scheme, project: project) }
  let(:tier) { create(:membership_tier, membership_scheme: scheme) }
  let(:customer) do
    create(:customer, project: project, external_id: "cust-1", name: "Jane", email: "jane@example.com", phone_number: "+15551234567",
                       country: "US", date_of_birth: Date.new(1990, 1, 1), marketing_opt_in: true,
                       membership_tier: tier, metadata: { tier: "gold" })
  end

  it "copies every field from the source customer" do
    duplicate = described_class.new(customer: customer).call

    expect(duplicate.name).to eq("Jane")
    expect(duplicate.email).to eq("jane@example.com")
    expect(duplicate.phone_number).to eq("+15551234567")
    expect(duplicate.country).to eq("US")
    expect(duplicate.date_of_birth).to eq(Date.new(1990, 1, 1))
    expect(duplicate.marketing_opt_in).to eq(true)
    expect(duplicate.membership_tier_id).to eq(tier.id)
    expect(duplicate.metadata.to_h).to eq({ "tier" => "gold" })
  end

  it "keys the duplicate as 'Copy of <external_id>'" do
    duplicate = described_class.new(customer: customer).call
    expect(duplicate.external_id).to eq("Copy of cust-1")
  end

  it "keys a second duplicate as 'Copy of <external_id> (2)'" do
    described_class.new(customer: customer).call
    second = described_class.new(customer: customer).call
    expect(second.external_id).to eq("Copy of cust-1 (2)")
  end

  it "keys a third duplicate as 'Copy of <external_id> (3)'" do
    described_class.new(customer: customer).call
    described_class.new(customer: customer).call
    third = described_class.new(customer: customer).call
    expect(third.external_id).to eq("Copy of cust-1 (3)")
  end

  it "persists the duplicate as a distinct row" do
    duplicate = described_class.new(customer: customer).call
    expect(duplicate.id).not_to eq(customer.id)
    expect(Customer.where(project_id: project.id).count).to eq(2)
  end
end
