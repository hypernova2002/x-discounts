require "rails_helper"

RSpec.describe Redemption do
  let(:record) { create(:redemption) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it "rejects a missing discount_id" do
    record.discount_id = nil
    expect(record).not_to be_valid
  end

  it "rejects a missing customer_id" do
    record.customer_id = nil
    expect(record).not_to be_valid
  end

  it "rejects a missing redeemed_at" do
    record.redeemed_at = nil
    expect(record).not_to be_valid
  end

  it "rejects a missing coupon_code_id" do
    record.coupon_code_id = nil
    expect(record).not_to be_valid
  end

  describe "#audit_project_id" do
    it "delegates to the discount's project_id" do
      expect(record.audit_project_id).to eq(record.discount.project_id)
    end
  end
end
