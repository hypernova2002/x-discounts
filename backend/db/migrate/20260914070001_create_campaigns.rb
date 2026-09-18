# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:campaigns) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      column :name, "text", null: false
      column :enabled, "boolean", null: false, default: true
      column :valid_from, "timestamptz"
      column :valid_until, "timestamptz"
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:project_id]
      index [:public_id], unique: true, name: :campaigns_public_id_unique
    end
  end
end
