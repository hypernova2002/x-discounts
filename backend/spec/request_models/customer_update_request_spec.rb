require "rails_helper"

RSpec.describe CustomerUpdateRequest do
  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "distinguishes an omitted membership_tier_id from an explicit null" do
    expect(described_class.new({}).attributes.key?(:membership_tier_id)).to eq(false)
    expect(described_class.new(membership_tier_id: nil).attributes.key?(:membership_tier_id)).to eq(true)
  end

  it "accepts a present membership_tier_id (assigning a tier)" do
    record = described_class.new(membership_tier_id: "mtier_abc123")
    expect(record.membership_tier_id).to eq("mtier_abc123")
  end

  it "rejects a non-string membership_tier_id" do
    expect { described_class.new(membership_tier_id: 123) }.to raise_error(Dry::Struct::Error)
  end
end
