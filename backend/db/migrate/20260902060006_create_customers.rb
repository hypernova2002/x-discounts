# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :customers do
      primary_key :id
      foreign_key :project_id, :projects, null: false

      String :external_id, null: false
      column :metadata, :jsonb, null: false, default: "{}"

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:project_id, :external_id], unique: true
    end
  end
end
