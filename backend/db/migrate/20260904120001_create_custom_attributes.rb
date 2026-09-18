# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:custom_attributes) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      column :entity, "text", null: false
      column :key, "text", null: false
      column :data_type, "text", null: false
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:project_id]
      index %i[project_id entity key], unique: true, name: :custom_attributes_project_entity_key_unique
      index [:public_id], unique: true, name: :custom_attributes_public_id_unique
    end
  end
end
