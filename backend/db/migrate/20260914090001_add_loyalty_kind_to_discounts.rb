# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:discounts) do
      drop_constraint :valid_kind
      add_constraint(:valid_kind) { kind =~ %w[promotion coupon loyalty] }
    end
  end

  down do
    alter_table(:discounts) do
      drop_constraint :valid_kind
      add_constraint(:valid_kind) { kind =~ %w[promotion coupon] }
    end
  end
end
