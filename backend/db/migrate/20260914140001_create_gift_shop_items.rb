# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:gift_shop_items) do
      primary_key :id
      foreign_key :project_id, :projects, null: false

      column :name, "text", null: false
      column :description, "text"
      column :points_cost, "integer", null: false
      # Nullable — null means unlimited stock.
      column :stock, "integer"
      column :enabled, "boolean", null: false, default: true

      # Bespoke local-disk photo storage (metadata only here — bytes live under
      # storage/gift_shop_items/<public_id><ext> on disk). This app is Sequel-only
      # with no ActiveRecord, and ActiveStorage hard-depends on ActiveRecord, so a
      # small dedicated field set is far simpler than wiring in a second ORM.
      column :photo_filename, "text"
      column :photo_content_type, "text"
      column :photo_byte_size, "bigint"

      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:project_id]
      index [:public_id], unique: true, name: :gift_shop_items_public_id_unique
    end
  end
end
