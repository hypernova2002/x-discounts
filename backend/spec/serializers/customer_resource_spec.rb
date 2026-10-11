# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerResource do
  it "omits membership_tier by default" do
    customer = create(:customer)

    expect(described_class.new(customer).to_h).not_to have_key("membership_tier")
  end

  it "forwards a single flat includes set two levels deep: membership_tier, then its own nested membership_scheme" do
    tier = create(:membership_tier)
    customer = create(:customer, project: tier.membership_scheme.project, membership_tier: tier)

    hash = described_class.new(customer, params: { includes: %w[membership_tier membership_scheme] }).to_h

    expect(hash["membership_tier"]).to be_present
    expect(hash["membership_tier"]["membership_scheme"]).to eq(id: tier.membership_scheme.public_id, name: tier.membership_scheme.name)
  end

  it "omits the nested membership_scheme when only membership_tier is requested" do
    tier = create(:membership_tier)
    customer = create(:customer, project: tier.membership_scheme.project, membership_tier: tier)

    hash = described_class.new(customer, params: { includes: ["membership_tier"] }).to_h

    expect(hash["membership_tier"]).not_to have_key("membership_scheme")
  end
end
