# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :discount_stacking_compatibilities do
      primary_key :id
      foreign_key :discount_id, :discounts, null: false
      foreign_key :compatible_discount_id, :discounts, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:discount_id, :compatible_discount_id], unique: true
      constraint(:no_self_stacking) { discount_id != compatible_discount_id }
    end
  end
end
