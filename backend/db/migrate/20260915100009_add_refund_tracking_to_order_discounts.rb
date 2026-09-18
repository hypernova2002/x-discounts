# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:order_discounts) do
      add_column :refunded_amount_off, "numeric", null: false, default: 0
      add_column :refunded_points, "integer", null: false, default: 0
      add_column :refunded_at, "timestamptz"
    end
  end
end
