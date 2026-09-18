# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:membership_schemes) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      column :name, "text", null: false
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:project_id]
      index [:public_id], unique: true, name: :membership_schemes_public_id_unique
    end
  end
end
