# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:customers) do
      add_foreign_key :membership_tier_id, :membership_tiers, on_delete: :set_null
      add_index :membership_tier_id
    end
  end
end
