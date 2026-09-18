# frozen_string_literal: true

Sequel.migration do
  up do
    drop_table(:refunds)
  end

  down do
    raise Sequel::Error, "not reversible — replaced by discount_refunds and the loyalty points ledger"
  end
end
