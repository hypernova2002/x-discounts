# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:activity_logs) do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      foreign_key :user_id, :users, null: true, on_delete: :set_null
      column :actor_label, "text"
      column :action, "text", null: false
      column :entity_type, "text", null: false
      column :entity_id, "integer"
      column :entity_public_id, "text"
      column :entity_label, "text", null: false
      column :changes, "jsonb", null: false, default: Sequel::LiteralString.new("'{}'::jsonb")
      column :request_id, "text"
      column :public_id, "text", null: false
      column :created_at, "timestamp with time zone", null: false, default: Sequel::CURRENT_TIMESTAMP

      index [:project_id, :created_at]
      index [:entity_type, :entity_id]
      index [:request_id]
      index [:public_id], name: :activity_logs_public_id_unique, unique: true
    end
  end
end
