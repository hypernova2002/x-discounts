# frozen_string_literal: true

# points_earned/refunded_points/refunded_amount_off/refunded_at all move off this
# snapshot row: earned points now live once on the linked loyalty_point_lot (avoids
# per-effect-row attribution, which is what caused the multiplier over/under-refund
# bug), and refund bookkeeping moves to discount_refunds / the points ledger.
Sequel.migration do
  up do
    alter_table(:order_discounts) do
      drop_column :points_earned
      drop_column :refunded_amount_off
      drop_column :refunded_points
      drop_column :refunded_at
    end
  end

  down do
    raise Sequel::Error, "not reversible"
  end
end
