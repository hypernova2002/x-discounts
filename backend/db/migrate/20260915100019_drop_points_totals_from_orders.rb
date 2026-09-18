# frozen_string_literal: true

# total_points_earned/total_points_redeemed are now computed from child rows
# (loyalty_point_lots for earned, points_redemption for redeemed) — see Order model.
Sequel.migration do
  up do
    alter_table(:orders) do
      drop_column :total_points_earned
      drop_column :total_points_redeemed
    end
  end

  down do
    raise Sequel::Error, "not reversible"
  end
end
