# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:discounts) do
      add_column :enabled, :boolean, null: false, default: true
    end
  end
end
