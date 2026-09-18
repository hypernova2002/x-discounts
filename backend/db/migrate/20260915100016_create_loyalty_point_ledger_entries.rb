# frozen_string_literal: true

# Append-only: every debit against a lot (spend or clawback) is its own row, never
# updated. A lot's points_remaining is computed as points + SUM(delta) — see
# LoyaltyPointLot#points_remaining. Lot creation itself is NOT an entry here; a lot's
# own `points`/`earned_at` already represent its birth as a credit. Entries only ever
# represent something being taken back out.
Sequel.migration do
  change do
    create_table(:loyalty_point_ledger_entries) do
      primary_key :id
      foreign_key :loyalty_point_lot_id, :loyalty_point_lots, null: false
      column :public_id, "text", null: false
      column :delta, "integer", null: false
      column :kind, "text", null: false # spend | clawback
      foreign_key :points_redemption_id, :points_redemptions, null: true, on_delete: :set_null
      foreign_key :gift_shop_redemption_id, :gift_shop_redemptions, null: true, on_delete: :set_null
      foreign_key :order_discount_id, :order_discounts, null: true, on_delete: :set_null
      column :created_at, "timestamptz", null: false

      index [:loyalty_point_lot_id]
      index [:points_redemption_id]
      index [:gift_shop_redemption_id]
      index [:order_discount_id]
      index [:public_id], unique: true, name: :loyalty_point_ledger_entries_public_id_unique
    end
  end
end
