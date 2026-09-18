# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:campaigns) do
      add_column :archived, :boolean, null: false, default: false
    end
  end
end
