# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :redemptions do
      primary_key :id
      foreign_key :coupon_id, :coupons, null: false
      foreign_key :customer_id, :customers, null: false

      DateTime :redeemed_at, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :coupon_id
      index :customer_id
    end
  end
end
