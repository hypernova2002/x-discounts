# frozen_string_literal: true

require "securerandom"

# Points earned before this feature existed have no per-discount expiration policy to
# derive a date from, so they're backfilled as a single non-expiring "legacy" lot per
# customer — points_remaining reflects whatever they haven't already redeemed, so
# nothing already spent becomes spendable again.
Sequel.migration do
  up do
    now = Time.now.utc

    from(:customers).each do |customer|
      earned = from(:orders).where(customer_id: customer[:id]).sum(:total_points_earned).to_i
      redeemed = from(:orders).where(customer_id: customer[:id]).sum(:total_points_redeemed).to_i
      next if earned <= 0

      from(:loyalty_point_lots).insert(
        customer_id: customer[:id],
        order_id: nil,
        discount_id: nil,
        points: earned,
        points_remaining: [earned - redeemed, 0].max,
        earned_at: customer[:created_at] || now,
        expires_at: nil,
        public_id: "lot_#{SecureRandom.alphanumeric(16).downcase}",
        created_at: now,
        updated_at: now
      )
    end
  end

  down do
    from(:loyalty_point_lots).where(order_id: nil, discount_id: nil).delete
  end
end
