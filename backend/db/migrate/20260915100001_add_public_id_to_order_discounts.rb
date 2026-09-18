# frozen_string_literal: true

require "securerandom"

Sequel.migration do
  up do
    alter_table(:order_discounts) { add_column :public_id, "text" }

    from(:order_discounts).select(:id).each do |row|
      from(:order_discounts).where(id: row[:id]).update(public_id: "ordisc_#{SecureRandom.alphanumeric(16).downcase}")
    end

    alter_table(:order_discounts) do
      set_column_not_null :public_id
      add_index :public_id, unique: true, name: :order_discounts_public_id_unique
    end
  end

  down do
    alter_table(:order_discounts) do
      drop_index :public_id, name: :order_discounts_public_id_unique
      drop_column :public_id
    end
  end
end
