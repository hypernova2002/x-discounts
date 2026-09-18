# frozen_string_literal: true

require "securerandom"

Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :name, "text"
      add_column :email, "text"
      add_column :phone_number, "text"
      add_column :country, "text"
      add_column :date_of_birth, "date"
      add_column :marketing_opt_in, "boolean", null: false, default: false
      add_column :public_id, String
    end

    self[:customers].select(:id).each do |row|
      self[:customers].where(id: row[:id]).update(public_id: "cust_#{SecureRandom.alphanumeric(16).downcase}")
    end

    alter_table(:customers) do
      set_column_not_null :public_id
      add_index :public_id, unique: true, name: :customers_public_id_unique
    end
  end

  down do
    alter_table(:customers) do
      drop_index :public_id, name: :customers_public_id_unique
      drop_column :public_id
      drop_column :marketing_opt_in
      drop_column :date_of_birth
      drop_column :country
      drop_column :phone_number
      drop_column :email
      drop_column :name
    end
  end
end
