# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:exports) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      foreign_key :user_id, :users, null: true, on_delete: :set_null
      column :export_type, "text", null: false
      column :params, "jsonb", null: false, default: Sequel::LiteralString.new("'{}'::jsonb")
      column :status, "text", null: false, default: "pending"
      column :filename, "text"
      column :content_type, "text"
      column :byte_size, "integer"
      column :error_message, "text"
      column :public_id, "text", null: false
      column :created_at, "timestamp with time zone", null: false, default: Sequel::CURRENT_TIMESTAMP
      column :completed_at, "timestamp with time zone"

      index [:project_id, :created_at]
      index [:public_id], name: :exports_public_id_unique, unique: true
    end
  end
end
