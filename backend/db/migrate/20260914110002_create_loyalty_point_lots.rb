# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:loyalty_point_lots) do
      primary_key :id
      foreign_key :customer_id, :customers, null: false
      # Snapshot/audit only — order history is a snapshot elsewhere in this schema too,
      # so deleting the source order or discount must not destroy the lot itself (the
      # customer keeps whatever they legitimately earned).
      foreign_key :order_id, :orders, null: true, on_delete: :set_null
      foreign_key :discount_id, :discounts, null: true, on_delete: :set_null

      column :points, "integer", null: false
      column :points_remaining, "integer", null: false
      column :earned_at, "timestamptz", null: false
      column :expires_at, "timestamptz"
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:customer_id]
      index %i[customer_id expires_at]
      index [:public_id], unique: true, name: :loyalty_point_lots_public_id_unique
    end
  end
end
