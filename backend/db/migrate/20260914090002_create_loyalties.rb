# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :loyalties do
      primary_key :id
      foreign_key :discount_id, :discounts, null: false, unique: true

      DateTime :active_from, null: false
      DateTime :active_until

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
