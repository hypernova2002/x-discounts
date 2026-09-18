# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:orders) do
      add_column :total_points_redeemed, "integer", null: false, default: 0
    end
  end
end
