# frozen_string_literal: true

# Snapshot of which line item a line-item-scoped effect applied to (nil for
# cart-scoped effects) — lets the order view group discounts under their line item
# like a real receipt, instead of a flat list with no connection back to what they
# discounted.
Sequel.migration do
  change do
    alter_table(:order_discounts) do
      add_column :sku, "text"
    end
  end
end
