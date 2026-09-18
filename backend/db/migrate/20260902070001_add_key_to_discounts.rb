# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :discounts, :key, String

    # Backfill any pre-existing rows with a placeholder so the NOT NULL + unique
    # constraints below can be added in the same migration.
    self[:discounts].update(key: Sequel.lit("'discount-' || id::text"))

    alter_table :discounts do
      set_column_not_null :key
      add_index [:project_id, :key], unique: true, name: :discounts_project_id_key_unique
    end
  end

  down do
    alter_table :discounts do
      drop_index [:project_id, :key], name: :discounts_project_id_key_unique
      drop_column :key
    end
  end
end
