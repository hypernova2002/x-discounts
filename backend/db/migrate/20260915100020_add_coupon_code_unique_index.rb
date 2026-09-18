# frozen_string_literal: true

# coupons.code used to be unique per project via a plain composite index; code now
# lives in discounts.kind_config, so this is a partial expression index instead.
Sequel.migration do
  up do
    run <<~SQL
      CREATE UNIQUE INDEX discounts_project_id_coupon_code_unique
      ON discounts (project_id, (kind_config->>'code'))
      WHERE kind = 'coupon'
    SQL
  end

  down do
    run "DROP INDEX discounts_project_id_coupon_code_unique"
  end
end
