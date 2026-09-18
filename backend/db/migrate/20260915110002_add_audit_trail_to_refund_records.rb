# frozen_string_literal: true

# Optional reason + who performed it, on every refund-producing record. Nullable
# throughout — a spend ledger entry has no reason/actor (it's a customer redemption,
# not an admin action), and the acting user is only known for session/API-key
# requests, which is all of them, but kept nullable for safety.
Sequel.migration do
  change do
    alter_table(:discount_refunds) do
      add_column :reason, "text"
      add_foreign_key :performed_by_user_id, :users, null: true, on_delete: :set_null
    end

    alter_table(:loyalty_point_ledger_entries) do
      add_column :reason, "text"
      add_foreign_key :performed_by_user_id, :users, null: true, on_delete: :set_null
    end

    alter_table(:loyalty_point_lots) do
      add_column :reason, "text"
      add_foreign_key :performed_by_user_id, :users, null: true, on_delete: :set_null
    end
  end
end
