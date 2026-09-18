# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:order_discounts) do
      add_foreign_key :loyalty_point_lot_id, :loyalty_point_lots, null: true, on_delete: :set_null
      add_index :loyalty_point_lot_id
    end

    # Best-effort backfill for pre-existing rows: a loyalty discount with several
    # effects can contribute several order_discount rows for the same (order,
    # discount) pair, but create_points_lot only ever creates one lot per pair —
    # so all of them point at the same lot here, same as new rows going forward.
    from(:order_discounts).where(kind: "loyalty").exclude(discount_id: nil).distinct.select(:order_id, :discount_id).each do |pair|
      lot = from(:loyalty_point_lots).where(order_id: pair[:order_id], discount_id: pair[:discount_id]).first
      next unless lot

      from(:order_discounts)
        .where(order_id: pair[:order_id], discount_id: pair[:discount_id], kind: "loyalty")
        .update(loyalty_point_lot_id: lot[:id])
    end
  end

  down do
    alter_table(:order_discounts) { drop_column :loyalty_point_lot_id }
  end
end
