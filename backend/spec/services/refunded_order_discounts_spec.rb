# frozen_string_literal: true

require "rails_helper"

RSpec.describe RefundedOrderDiscounts do
  describe ".ids_among" do
    it "flags a coupon/promotion row as refunded only once a DiscountRefund exists for it" do
      plain = create(:order_discount, kind: "coupon")
      refunded = create(:order_discount, kind: "coupon")
      create(:discount_refund, order_discount: refunded)

      ids = described_class.ids_among([plain, refunded])

      expect(ids).to contain_exactly(refunded.id)
    end

    it "flags a loyalty row as refunded only once a clawback ledger entry references it" do
      lot = create(:loyalty_point_lot)
      plain = create(:order_discount, kind: "loyalty", loyalty_point_lot: lot)
      clawed_back = create(:order_discount, kind: "loyalty", loyalty_point_lot: lot)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: clawed_back)

      ids = described_class.ids_among([plain, clawed_back])

      expect(ids).to contain_exactly(clawed_back.id)
    end

    it "returns an empty set for an empty batch without querying either refund table" do
      expect(described_class.ids_among([])).to be_empty
    end
  end
end
