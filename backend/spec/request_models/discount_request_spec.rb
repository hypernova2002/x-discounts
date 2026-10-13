require "rails_helper"

RSpec.describe DiscountRequest do
  describe ".build" do
    it "dispatches a promotion kind to PromotionDiscountRequest" do
      body = { kind: "promotion", name: "Sitewide 10%", campaign_id: "camp_1", promotion: { active_from: "2026-01-01T00:00:00Z" } }
      record = described_class.build(body)
      expect(record).to be_a(PromotionDiscountRequest)
      expect(record.name).to eq("Sitewide 10%")
    end

    it "dispatches a coupon kind to CouponDiscountRequest" do
      body = { kind: "coupon", name: "Save 10", campaign_id: "camp_1", coupon: {} }
      expect(described_class.build(body)).to be_a(CouponDiscountRequest)
    end

    it "dispatches a loyalty kind to LoyaltyDiscountRequest" do
      body = { kind: "loyalty", name: "Earn Points", campaign_id: "camp_1", loyalty: { active_from: "2026-01-01T00:00:00Z" } }
      expect(described_class.build(body)).to be_a(LoyaltyDiscountRequest)
    end

    it "raises a ValidationError on kind: field for an unrecognized kind" do
      expect { described_class.build({ kind: "bogus" }) }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "kind"))
      end
    end

    it "raises a ValidationError for a missing kind" do
      expect { described_class.build({}) }.to raise_error(ValidationError)
    end
  end
end
