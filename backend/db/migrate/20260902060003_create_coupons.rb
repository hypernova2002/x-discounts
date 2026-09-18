# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :coupons do
      primary_key :id
      foreign_key :discount_id, :discounts, null: false, unique: true
      # Denormalized from discounts.project_id so code uniqueness can be
      # scoped per-project with a plain composite index on this table.
      foreign_key :project_id, :projects, null: false

      String :code, null: false

      DateTime :issued_from
      DateTime :issued_until
      DateTime :valid_from
      DateTime :valid_until

      Integer :max_redemptions
      Integer :max_redemptions_per_customer

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :project_id
      index [:project_id, :code], unique: true
    end
  end
end
