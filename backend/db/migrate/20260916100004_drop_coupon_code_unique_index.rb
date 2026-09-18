# frozen_string_literal: true

# Dead now that code lives in coupon_codes, not discounts.kind_config — and coupon
# codes are intentionally not unique at the DB level anyway (see create_coupon_codes).
Sequel.migration do
  up do
    run "DROP INDEX IF EXISTS discounts_project_id_coupon_code_unique"
  end

  down do
    run <<~SQL
      CREATE UNIQUE INDEX discounts_project_id_coupon_code_unique
      ON discounts (project_id, (kind_config->>'code'))
      WHERE kind = 'coupon'
    SQL
  end
end
