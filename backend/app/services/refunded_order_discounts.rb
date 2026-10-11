# frozen_string_literal: true

# Bulk version of OrderDiscount#refunded? — given a batch of OrderDiscount rows
# (each needs :id and :kind loaded), returns the ids that are refunded, in 2
# queries total instead of 1-2 per row. Same refund philosophy as the row-level
# method: loyalty rows are refunded via a ledger clawback, the other two kinds
# via a DiscountRefund record.
module RefundedOrderDiscounts
  def self.ids_among(order_discounts)
    loyalty_ids, non_loyalty_ids = order_discounts.partition { |od| od.kind == "loyalty" }.map { |group| group.map(&:id) }

    clawed_back_ids = LoyaltyPointLedgerEntry.where(kind: "clawback", order_discount_id: loyalty_ids).select_map(:order_discount_id)
    refunded_ids = DiscountRefund.where(order_discount_id: non_loyalty_ids).select_map(:order_discount_id)

    (clawed_back_ids + refunded_ids).to_set
  end
end
