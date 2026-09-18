# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:membership_tiers) do
      add_column :requirements_condition, "jsonb", null: false, default: "{}"
    end
  end
end
