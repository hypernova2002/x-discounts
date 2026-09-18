# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:orders) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      foreign_key :customer_id, :customers, null: false
      column :total_amount, "numeric", null: false, default: 0
      column :total_discount_amount, "numeric", null: false, default: 0
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:project_id]
      index [:customer_id]
      index [:public_id], unique: true, name: :orders_public_id_unique
    end
  end
end
