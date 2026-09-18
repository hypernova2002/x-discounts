# frozen_string_literal: true

# Moves max_redemptions/max_redemptions_per_customer from Coupon to Discount, joining
# the four newer usage/spend limits there — so promotions get them too, and so all six
# limits are counted the same way (via OrderDiscount, not the coupon-only Redemption
# table). Existing values are carried over, not dropped.
Sequel.migration do
  up do
    alter_table(:discounts) do
      add_column :max_redemptions, "integer"
      add_column :max_redemptions_per_customer, "integer"
    end

    from(:coupons).each do |coupon|
      next unless coupon[:max_redemptions] || coupon[:max_redemptions_per_customer]

      from(:discounts).where(id: coupon[:discount_id]).update(
        max_redemptions: coupon[:max_redemptions],
        max_redemptions_per_customer: coupon[:max_redemptions_per_customer]
      )
    end

    alter_table(:coupons) do
      drop_column :max_redemptions
      drop_column :max_redemptions_per_customer
    end
  end

  down do
    alter_table(:coupons) do
      add_column :max_redemptions, "integer"
      add_column :max_redemptions_per_customer, "integer"
    end

    from(:discounts).where(kind: "coupon").each do |discount|
      next unless discount[:max_redemptions] || discount[:max_redemptions_per_customer]

      coupon = from(:coupons).where(discount_id: discount[:id]).first
      next unless coupon

      from(:coupons).where(id: coupon[:id]).update(
        max_redemptions: discount[:max_redemptions],
        max_redemptions_per_customer: discount[:max_redemptions_per_customer]
      )
    end

    alter_table(:discounts) do
      drop_column :max_redemptions
      drop_column :max_redemptions_per_customer
    end
  end
end
