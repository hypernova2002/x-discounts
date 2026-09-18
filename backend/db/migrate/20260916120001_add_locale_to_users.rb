# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:users) do
      add_column :locale, "text", null: false, default: "en"
    end
  end
end
