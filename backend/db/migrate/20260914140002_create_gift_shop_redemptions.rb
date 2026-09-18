# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:gift_shop_redemptions) do
      primary_key :id
      foreign_key :customer_id, :customers, null: false
      # Nullable + set_null — redemption history is a snapshot (item_name/points_spent
      # below), so it must survive the item later being deleted or changed, same
      # pattern as order_discounts.discount_id.
      foreign_key :gift_shop_item_id, :gift_shop_items, null: true, on_delete: :set_null

      column :item_name, "text", null: false
      column :quantity, "integer", null: false, default: 1
      column :points_spent, "integer", null: false
      column :redeemed_at, "timestamptz", null: false

      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:customer_id]
      index [:gift_shop_item_id]
      index [:public_id], unique: true, name: :gift_shop_redemptions_public_id_unique
    end
  end
end
