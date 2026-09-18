# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:orders) do
      add_column :cancelled_at, "timestamptz"
    end
  end
end
