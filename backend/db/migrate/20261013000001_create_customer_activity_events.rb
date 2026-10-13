# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:customer_activity_events) do
      primary_key :id
      foreign_key :customer_id, :customers, null: false
      foreign_key :project_id, :projects, null: false

      column :type, "text", null: false
      column :occurred_at, "timestamptz", null: false
      column :payload, "jsonb", null: false, default: Sequel::LiteralString.new("'{}'::jsonb")

      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false

      index [:customer_id, :occurred_at]
      index [:public_id], unique: true, name: :customer_activity_events_public_id_unique
    end
  end
end
