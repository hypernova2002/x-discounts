# frozen_string_literal: true

require "securerandom"

# Redemption is referenced by order_discounts.redemption_id and needs to be
# addressable from CSV exports without leaking the raw internal id — same
# public_id pattern every other business entity already has.
Sequel.migration do
  up do
    alter_table(:redemptions) { add_column :public_id, "text" }

    from(:redemptions).each do |r|
      from(:redemptions).where(id: r[:id]).update(public_id: "redm_#{SecureRandom.alphanumeric(16).downcase}")
    end

    alter_table(:redemptions) do
      set_column_not_null :public_id
      add_index :public_id, unique: true, name: :redemptions_public_id_unique
    end
  end

  down do
    alter_table(:redemptions) do
      drop_index :public_id, name: :redemptions_public_id_unique
      drop_column :public_id
    end
  end
end
