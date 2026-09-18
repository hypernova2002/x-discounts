# frozen_string_literal: true

Sequel.migration do
  up do
    # redemptions tracked coupon usage via coupons.id — coupons is going away, and
    # Discount is already the coupon (discriminated by kind), so repoint directly.
    alter_table(:redemptions) { add_foreign_key :discount_id, :discounts, null: true }
    from(:redemptions).each do |r|
      coupon = from(:coupons).where(id: r[:coupon_id]).first
      next unless coupon

      from(:redemptions).where(id: r[:id]).update(discount_id: coupon[:discount_id])
    end
    alter_table(:redemptions) do
      set_column_not_null :discount_id
      add_index :discount_id
      drop_column :coupon_id
    end

    drop_table(:promotions)
    drop_table(:coupons)
    drop_table(:loyalties)
  end

  down do
    raise Sequel::Error, "not reversible — kind_config on discounts is now the source of truth"
  end
end
