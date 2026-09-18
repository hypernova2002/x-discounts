# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:order_discounts) do
      add_column :points_earned, "integer"
    end
    alter_table(:orders) do
      add_column :total_points_earned, "integer", null: false, default: 0
    end
  end
end
