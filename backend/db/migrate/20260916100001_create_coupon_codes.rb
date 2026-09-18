# frozen_string_literal: true

# code is deliberately NOT unique at the DB level — the same string can be reused
# once its original discount is no longer "reserving" it (see Discount#coupon_code_reserved?).
# Uniqueness among currently-reserving discounts is enforced at the app layer in
# CouponCodes::GenerateService, since that condition can't be expressed as a plain
# or partial index. project_id is denormalized from discount_id purely so that check
# doesn't need a join.
Sequel.migration do
  change do
    create_table(:coupon_codes) do
      primary_key :id
      foreign_key :discount_id, :discounts, null: false
      foreign_key :project_id, :projects, null: false
      foreign_key :customer_id, :customers, null: true, on_delete: :set_null
      column :public_id, "text", null: false
      column :code, "text", null: false
      column :max_redemptions, "integer", null: false, default: 1
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:discount_id]
      index [:customer_id]
      index [:project_id, :code]
      index [:public_id], unique: true, name: :coupon_codes_public_id_unique
    end

    alter_table(:redemptions) do
      add_foreign_key :coupon_code_id, :coupon_codes, null: true
      add_index :coupon_code_id
    end
  end
end
