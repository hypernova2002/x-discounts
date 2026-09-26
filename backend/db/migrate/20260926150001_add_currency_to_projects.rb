# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_column :currency, "text", null: false, default: "USD"
    end
  end
end
