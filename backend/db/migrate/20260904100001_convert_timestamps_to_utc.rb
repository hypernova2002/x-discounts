# frozen_string_literal: true

# Every existing "timestamp without time zone" value was written by app/db processes
# running in UTC (confirmed via the container clock), so reinterpreting the raw wall-clock
# value as UTC via `AT TIME ZONE 'UTC'` is a lossless, non-destructive conversion.
timestamp_columns = {
  accounts: %i[created_at updated_at],
  projects: %i[created_at updated_at],
  users: %i[created_at updated_at],
  api_keys: %i[last_used_at revoked_at created_at updated_at],
  customers: %i[created_at updated_at],
  discounts: %i[created_at updated_at],
  project_memberships: %i[created_at updated_at],
  sessions: %i[expires_at last_used_at created_at updated_at],
  coupons: %i[issued_from issued_until valid_from valid_until created_at updated_at],
  discount_effects: %i[created_at updated_at],
  discount_stacking_compatibilities: %i[created_at updated_at],
  promotions: %i[active_from active_until created_at updated_at],
  redemptions: %i[redeemed_at created_at updated_at]
}.freeze

Sequel.migration do
  up do
    timestamp_columns.each do |table, columns|
      alter_table(table) do
        columns.each do |column|
          set_column_type column, "timestamptz", using: Sequel.lit("#{column} AT TIME ZONE 'UTC'")
        end
      end
    end
  end

  down do
    timestamp_columns.each do |table, columns|
      alter_table(table) do
        columns.each do |column|
          set_column_type column, "timestamp", using: Sequel.lit("#{column} AT TIME ZONE 'UTC'")
        end
      end
    end
  end
end
