# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:loyalty_point_lots) do
      drop_column :points_remaining
      add_foreign_key :refund_of_points_redemption_id, :points_redemptions, null: true, on_delete: :set_null
      add_index :refund_of_points_redemption_id
    end
  end

  down do
    raise Sequel::Error, "not reversible — points_remaining is now computed from the ledger"
  end
end
