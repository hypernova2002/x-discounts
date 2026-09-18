# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:refunds) do
      primary_key :id
      foreign_key :order_id, :orders, null: false
      # Exactly one of these two is set — a refund always targets either an
      # applied discount line or a points redemption, never both.
      foreign_key :order_discount_id, :order_discounts, null: true, on_delete: :set_null
      foreign_key :points_redemption_id, :points_redemptions, null: true, on_delete: :set_null
      column :public_id, "text", null: false
      column :amount_off, "numeric"
      column :points, "integer"
      column :reason, "text"
      column :refunded_at, "timestamptz", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:order_id]
      index [:order_discount_id]
      index [:points_redemption_id]
      index [:public_id], unique: true, name: :refunds_public_id_unique
    end
  end
end
