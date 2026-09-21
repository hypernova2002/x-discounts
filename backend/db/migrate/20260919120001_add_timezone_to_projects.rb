# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :timezone, "text", null: false, default: "UTC"
    end
  end
end
