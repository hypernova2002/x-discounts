# frozen_string_literal: true

require "rails_helper"

RSpec.describe CouponCodes::BulkStatsService do
  describe "#call" do
    it "counts redemptions per coupon code, excluding refunded ones" do
      code_a = create(:coupon, max_redemptions: 5)
      code_b = create(:coupon, max_redemptions: 5)

      redemption_a1 = create(:redemption, coupon_code: code_a)
      create(:order_discount, discount: code_a.discount, kind: "coupon", redemption: redemption_a1)

      redemption_a2 = create(:redemption, coupon_code: code_a)
      refunded_od = create(:order_discount, discount: code_a.discount, kind: "coupon", redemption: redemption_a2)
      create(:discount_refund, order_discount: refunded_od)

      redemption_b1 = create(:redemption, coupon_code: code_b)
      create(:order_discount, discount: code_b.discount, kind: "coupon", redemption: redemption_b1)

      counts = described_class.new([code_a, code_b]).call.redemption_counts

      expect(counts[code_a.id]).to eq(1)
      expect(counts[code_b.id]).to eq(1)
    end

    it "omits codes with no redemptions from the map rather than returning 0" do
      unused_code = create(:coupon)

      counts = described_class.new([unused_code]).call.redemption_counts

      expect(counts).not_to have_key(unused_code.id)
    end

    it "returns an empty map for an empty batch" do
      expect(described_class.new([]).call.redemption_counts).to eq({})
    end
  end
end
