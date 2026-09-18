# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:order_line_items) do
      primary_key :id
      foreign_key :order_id, :orders, null: false
      column :sku, "text", null: false
      column :quantity, "integer", null: false
      column :unit_price, "numeric", null: false
      column :metadata, "jsonb", default: Sequel.lit("'{}'::jsonb"), null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:order_id]
    end
  end
end
