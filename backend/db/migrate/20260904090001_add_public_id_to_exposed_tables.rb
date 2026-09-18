# frozen_string_literal: true

require "securerandom"

Sequel.migration do
  TABLE_PREFIXES = {
    accounts: "acct",
    users: "usr",
    projects: "proj",
    project_memberships: "memb",
    api_keys: "key",
    discounts: "disc",
    discount_effects: "eff"
  }.freeze

  up do
    TABLE_PREFIXES.each do |table, prefix|
      add_column table, :public_id, String

      self[table].select(:id).each do |row|
        public_id = "#{prefix}_#{SecureRandom.alphanumeric(16).downcase}"
        self[table].where(id: row[:id]).update(public_id: public_id)
      end

      alter_table table do
        set_column_not_null :public_id
        add_index :public_id, unique: true, name: :"#{table}_public_id_unique"
      end
    end
  end

  down do
    TABLE_PREFIXES.each_key do |table|
      alter_table table do
        drop_index :public_id, name: :"#{table}_public_id_unique"
        drop_column :public_id
      end
    end
  end
end
