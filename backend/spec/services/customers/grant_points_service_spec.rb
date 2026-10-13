require "rails_helper"

RSpec.describe Customers::GrantPointsService do
  let(:project) { create(:project) }
  let(:customer) { create(:customer, project: project) }
  let(:admin_user) { create(:user) }

  it "creates a manual_grant loyalty_point_lot with the given attributes" do
    expires_at = 30.days.from_now
    lot = described_class.new(customer: customer, points: 100, expires_at: expires_at, reason: "goodwill", performed_by: admin_user).call

    expect(lot).to be_a(LoyaltyPointLot)
    expect(lot.source).to eq("manual_grant")
    expect(lot.points).to eq(100)
    expect(lot.expires_at).to be_within(1.second).of(expires_at)
    expect(lot.reason).to eq("goodwill")
    expect(lot.performed_by_user_id).to eq(admin_user.id)
  end

  it "persists the lot against the customer" do
    described_class.new(customer: customer, points: 50).call
    expect(customer.loyalty_point_lots_dataset.count).to eq(1)
  end

  it "raises on field points for a zero amount" do
    expect { described_class.new(customer: customer, points: 0).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "points"))
    end
  end

  it "raises on field points for a negative amount" do
    expect { described_class.new(customer: customer, points: -10).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "points"))
    end
  end

  it "coerces a numeric-string points value" do
    lot = described_class.new(customer: customer, points: "50").call
    expect(lot.points).to eq(50)
  end

  it "coerces a float points value via to_i" do
    lot = described_class.new(customer: customer, points: 50.9).call
    expect(lot.points).to eq(50)
  end

  it "works with no expires_at, reason, or performed_by given" do
    lot = described_class.new(customer: customer, points: 10).call
    expect(lot.expires_at).to be_nil
    expect(lot.reason).to be_nil
    expect(lot.performed_by_user_id).to be_nil
  end
end
