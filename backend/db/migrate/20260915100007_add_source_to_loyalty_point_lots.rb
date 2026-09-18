# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:loyalty_point_lots) { add_column :source, "text" }

    from(:loyalty_point_lots).exclude(order_id: nil).update(source: "order")
    from(:loyalty_point_lots).where(order_id: nil).update(source: "legacy_backfill")

    alter_table(:loyalty_point_lots) { set_column_not_null :source }
  end

  down do
    alter_table(:loyalty_point_lots) { drop_column :source }
  end
end
