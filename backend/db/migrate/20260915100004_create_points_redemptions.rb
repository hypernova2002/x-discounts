# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:points_redemptions) do
      primary_key :id
      foreign_key :order_id, :orders, null: false
      foreign_key :customer_id, :customers, null: false
      column :public_id, "text", null: false
      column :points_redeemed, "integer", null: false
      column :amount_off, "numeric", null: false
      column :refunded_points, "integer", null: false, default: 0
      column :refunded_at, "timestamptz"
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:order_id], unique: true, name: :points_redemptions_order_id_unique
      index [:customer_id]
      index [:public_id], unique: true, name: :points_redemptions_public_id_unique
    end
  end
end
