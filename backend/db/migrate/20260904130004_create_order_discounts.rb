# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:order_discounts) do
      primary_key :id
      foreign_key :order_id, :orders, null: false
      # Nullable + set_null: order history is a snapshot (discount_key/name/etc below),
      # so it must survive the original Discount or Redemption later being deleted.
      foreign_key :discount_id, :discounts, null: true, on_delete: :set_null
      foreign_key :redemption_id, :redemptions, null: true, on_delete: :set_null
      column :kind, "text", null: false
      column :discount_key, "text", null: false
      column :discount_name, "text", null: false
      column :effect_type, "text", null: false
      column :amount_off, "numeric"
      column :free_items, "jsonb"
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:order_id]
      index [:discount_id]
      index [:redemption_id]
    end
  end
end
