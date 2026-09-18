# frozen_string_literal: true

# Every Redemption now always has a coupon_code — there's no more shared-code path
# for it to be nullable against.
Sequel.migration do
  up do
    alter_table(:redemptions) do
      set_column_not_null :coupon_code_id
    end
  end

  down do
    alter_table(:redemptions) { set_column_allow_null :coupon_code_id }
  end
end
