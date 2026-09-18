# frozen_string_literal: true

# Money-only now that loyalty points refunds are ledger entries — no more polymorphic
# "exactly one of two FKs" shape, since this only ever targets an order_discount.
Sequel.migration do
  change do
    create_table(:discount_refunds) do
      primary_key :id
      foreign_key :order_discount_id, :order_discounts, null: false
      column :public_id, "text", null: false
      column :amount_off, "numeric", null: false
      column :refunded_at, "timestamptz", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:order_discount_id]
      index [:public_id], unique: true, name: :discount_refunds_public_id_unique
    end
  end
end
