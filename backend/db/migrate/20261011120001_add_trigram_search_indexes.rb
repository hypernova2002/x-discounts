# frozen_string_literal: true

# Every ilike("%...%") search in the app (campaigns/customers/orders/
# discounts/coupon_codes/membership_schemes/custom_attributes) was running as
# a full sequential scan — the existing unique btree indexes on public_id/
# code/external_id can't be used for a leading-wildcard pattern regardless.
Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    add_index :campaigns, :name, type: :gin, opclass: :gin_trgm_ops, name: :campaigns_name_trgm
    add_index :customers, :external_id, type: :gin, opclass: :gin_trgm_ops, name: :customers_external_id_trgm
    add_index :customers, :name, type: :gin, opclass: :gin_trgm_ops, name: :customers_name_trgm
    add_index :customers, :email, type: :gin, opclass: :gin_trgm_ops, name: :customers_email_trgm
    add_index :discounts, :name, type: :gin, opclass: :gin_trgm_ops, name: :discounts_name_trgm
    add_index :coupon_codes, :code, type: :gin, opclass: :gin_trgm_ops, name: :coupon_codes_code_trgm
    add_index :orders, :public_id, type: :gin, opclass: :gin_trgm_ops, name: :orders_public_id_trgm
    add_index :membership_schemes, :name, type: :gin, opclass: :gin_trgm_ops, name: :membership_schemes_name_trgm
    add_index :custom_attributes, :key, type: :gin, opclass: :gin_trgm_ops, name: :custom_attributes_key_trgm
  end

  down do
    drop_index :campaigns, :name, name: :campaigns_name_trgm
    drop_index :customers, :external_id, name: :customers_external_id_trgm
    drop_index :customers, :name, name: :customers_name_trgm
    drop_index :customers, :email, name: :customers_email_trgm
    drop_index :discounts, :name, name: :discounts_name_trgm
    drop_index :coupon_codes, :code, name: :coupon_codes_code_trgm
    drop_index :orders, :public_id, name: :orders_public_id_trgm
    drop_index :membership_schemes, :name, name: :membership_schemes_name_trgm
    drop_index :custom_attributes, :key, name: :custom_attributes_key_trgm

    run "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
