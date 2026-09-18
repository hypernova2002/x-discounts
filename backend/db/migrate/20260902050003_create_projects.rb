# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :projects do
      primary_key :id
      foreign_key :account_id, :accounts, null: false

      String :name, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :account_id
    end
  end
end
