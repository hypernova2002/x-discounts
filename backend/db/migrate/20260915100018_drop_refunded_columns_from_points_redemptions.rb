# frozen_string_literal: true

# refunded_points/refunded_at are now computed from loyalty_point_lots where
# refund_of_points_redemption_id = this row's id.
Sequel.migration do
  up do
    alter_table(:points_redemptions) do
      drop_column :refunded_points
      drop_column :refunded_at
    end
  end

  down do
    raise Sequel::Error, "not reversible"
  end
end
