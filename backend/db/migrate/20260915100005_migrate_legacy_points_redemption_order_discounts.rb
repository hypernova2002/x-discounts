# frozen_string_literal: true

require "securerandom"

# Points redemption used to be stored as an OrderDiscount row (kind:
# "points_redemption", discount_id: nil). It's now its own table so partial
# refunds can be tracked against it directly — move any existing rows over.
Sequel.migration do
  up do
    from(:order_discounts).where(kind: "points_redemption").each do |row|
      order = from(:orders).where(id: row[:order_id]).first
      next unless order

      now = Time.now.utc
      from(:points_redemptions).insert(
        order_id: row[:order_id],
        customer_id: order[:customer_id],
        public_id: "ptsr_#{SecureRandom.alphanumeric(16).downcase}",
        points_redeemed: row[:amount_off].to_i,
        amount_off: row[:amount_off],
        refunded_points: 0,
        refunded_at: nil,
        created_at: row[:created_at] || now,
        updated_at: row[:updated_at] || now
      )
    end

    from(:order_discounts).where(kind: "points_redemption").delete
  end

  down do
    # Not meaningfully reversible.
  end
end
