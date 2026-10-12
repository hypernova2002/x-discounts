# frozen_string_literal: true

# Fills gaps a fresh performance audit found: foreign keys with zero index
# coverage, and no created_at index on any table the analytics/activity-feed/
# usage-limit queries filter by date range on. Purely additive — no existing
# index is touched.
Sequel.migration do
  up do
    add_index :activity_logs, :user_id
    add_index :exports, :user_id
    add_index :discount_stacking_compatibilities, :compatible_discount_id
    add_index :loyalty_point_lots, :order_id
    add_index :loyalty_point_lots, :discount_id
    add_index :loyalty_point_lots, :performed_by_user_id
    add_index :discount_refunds, :performed_by_user_id
    add_index :loyalty_point_ledger_entries, :performed_by_user_id

    add_index :discount_refunds, :created_at
    add_index :loyalty_point_ledger_entries, :created_at

    add_index :orders, [:project_id, :created_at]
    add_index :orders, [:customer_id, :created_at]
    add_index :customers, [:project_id, :created_at]
    add_index :order_discounts, [:discount_id, :created_at]
  end

  down do
    drop_index :order_discounts, [:discount_id, :created_at]
    drop_index :customers, [:project_id, :created_at]
    drop_index :orders, [:customer_id, :created_at]
    drop_index :orders, [:project_id, :created_at]

    drop_index :loyalty_point_ledger_entries, :created_at
    drop_index :discount_refunds, :created_at

    drop_index :loyalty_point_ledger_entries, :performed_by_user_id
    drop_index :discount_refunds, :performed_by_user_id
    drop_index :loyalty_point_lots, :performed_by_user_id
    drop_index :loyalty_point_lots, :discount_id
    drop_index :loyalty_point_lots, :order_id
    drop_index :discount_stacking_compatibilities, :compatible_discount_id
    drop_index :exports, :user_id
    drop_index :activity_logs, :user_id
  end
end
