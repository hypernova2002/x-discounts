# frozen_string_literal: true

# Reverting the "reusable once inactive" design back to a flat, permanent uniqueness
# constraint — a code is unique across every coupon in the project, full stop, no
# app-layer "is the other discount still active" check needed. See
# Discount#coupon_code_reserved? and the app-layer checks in
# CouponCodes::GenerateService / ValidationService, both simplified in this same change.
Sequel.migration do
  change do
    alter_table(:coupon_codes) do
      drop_index [:project_id, :code]
      add_index [:project_id, :code], unique: true, name: :coupon_codes_project_id_code_unique
    end
  end
end
