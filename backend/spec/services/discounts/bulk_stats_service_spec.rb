# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discounts::BulkStatsService do
  describe "#call" do
    describe "redemption_counts" do
      it "counts non-refunded order_discounts per discount, across plain, coupon-refunded, and loyalty-clawed-back rows" do
        discount = create(:discount, kind: "promotion")
        create(:order_discount, discount: discount, kind: "promotion")

        refunded = create(:order_discount, discount: discount, kind: "promotion")
        create(:discount_refund, order_discount: refunded)

        lot = create(:loyalty_point_lot)
        clawed_back = create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: lot)
        create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: clawed_back)
        create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: lot)

        counts = described_class.new([discount]).call.redemption_counts

        expect(counts[discount.id]).to eq(2)
      end
    end

    describe "coupon_code_stats" do
      it "reports total and available (not-fully-redeemed) coupon codes, non-coupon discounts omitted" do
        coupon_discount = create(:discount, kind: "coupon")
        promo_discount = create(:discount, kind: "promotion")

        available_code = create(:coupon, discount: coupon_discount, max_redemptions: 2)
        redemption = create(:redemption, coupon_code: available_code)
        create(:order_discount, discount: coupon_discount, kind: "coupon", redemption: redemption)

        exhausted_code = create(:coupon, discount: coupon_discount, max_redemptions: 1)
        exhausted_redemption = create(:redemption, coupon_code: exhausted_code)
        create(:order_discount, discount: coupon_discount, kind: "coupon", redemption: exhausted_redemption)

        stats = described_class.new([coupon_discount, promo_discount]).call.coupon_code_stats

        expect(stats[coupon_discount.id]).to eq(total: 2, available: 1)
        expect(stats).not_to have_key(promo_discount.id)
      end
    end

    describe "discount_kinds_by_campaign" do
      it "groups distinct discount kinds per campaign in one query" do
        campaign = create(:campaign)
        create(:discount, campaign: campaign, kind: "promotion")
        create(:discount, campaign: campaign, kind: "coupon")

        kinds = described_class.new([create(:discount, campaign: campaign, kind: "promotion")]).call.discount_kinds_by_campaign

        expect(kinds[campaign.id]).to contain_exactly("promotion", "coupon")
      end
    end
  end
end
