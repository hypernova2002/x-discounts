# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:discounts) { add_column :kind_config, "jsonb", null: false, default: "{}" }

    from(:discounts).where(kind: "promotion").each do |d|
      promo = from(:promotions).where(discount_id: d[:id]).first
      next unless promo

      config = { active_from: promo[:active_from], active_until: promo[:active_until] }.compact
      from(:discounts).where(id: d[:id]).update(kind_config: Sequel.pg_jsonb(config))
    end

    from(:discounts).where(kind: "coupon").each do |d|
      coupon = from(:coupons).where(discount_id: d[:id]).first
      next unless coupon

      config = {
        code: coupon[:code], issued_from: coupon[:issued_from], issued_until: coupon[:issued_until],
        valid_from: coupon[:valid_from], valid_until: coupon[:valid_until]
      }.compact
      from(:discounts).where(id: d[:id]).update(kind_config: Sequel.pg_jsonb(config))
    end

    from(:discounts).where(kind: "loyalty").each do |d|
      loyalty = from(:loyalties).where(discount_id: d[:id]).first
      next unless loyalty

      config = {
        active_from: loyalty[:active_from], active_until: loyalty[:active_until],
        points_expire_after_days: loyalty[:points_expire_after_days]
      }.compact
      from(:discounts).where(id: d[:id]).update(kind_config: Sequel.pg_jsonb(config))
    end
  end

  down do
    alter_table(:discounts) { drop_column :kind_config }
  end
end
