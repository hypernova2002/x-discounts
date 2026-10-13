require "rails_helper"

RSpec.describe DiscountUpdateRequest do
  describe ".build" do
    it "dispatches kind: promotion to PromotionDiscountUpdateRequest" do
      expect(described_class.build({ name: "Renamed" }, kind: "promotion")).to be_a(PromotionDiscountUpdateRequest)
    end

    it "dispatches kind: coupon to CouponDiscountUpdateRequest" do
      expect(described_class.build({ name: "Renamed" }, kind: "coupon")).to be_a(CouponDiscountUpdateRequest)
    end

    it "dispatches kind: loyalty to LoyaltyDiscountUpdateRequest" do
      expect(described_class.build({ name: "Renamed" }, kind: "loyalty")).to be_a(LoyaltyDiscountUpdateRequest)
    end

    it "passes the body through to the dispatched struct" do
      record = described_class.build({ name: "Renamed" }, kind: "promotion")
      expect(record.name).to eq("Renamed")
    end
  end
end
