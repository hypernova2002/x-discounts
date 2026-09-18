# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :sessions do
      primary_key :id
      foreign_key :user_id, :users, null: false

      String :token_digest, null: false
      DateTime :expires_at, null: false
      DateTime :last_used_at

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :user_id
      index :token_digest, unique: true
    end
  end
end
