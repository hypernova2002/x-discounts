# frozen_string_literal: true

# Usage/spend limits live on Discount, not Coupon, so promotions get them too —
# unlike max_redemptions/max_redemptions_per_customer, which predate this and stay
# Coupon-only for now (a real inconsistency, not something to silently paper over).
Sequel.migration do
  change do
    alter_table(:discounts) do
      add_column :max_redemptions_per_day, "integer"
      add_column :max_redemption_amount, "numeric"
      add_column :max_redemption_amount_per_day, "numeric"
      add_column :max_redemption_amount_per_customer, "numeric"
    end
  end
end
