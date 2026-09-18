# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :api_keys do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      foreign_key :user_id, :users, null: false

      String :name, null: false
      String :role, null: false
      String :token_digest, null: false
      String :token_last_four, null: false

      DateTime :last_used_at
      DateTime :revoked_at

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :project_id
      index :user_id
      index :token_digest, unique: true

      constraint(:valid_role) { role =~ %w[admin developer marketer viewer] }
    end
  end
end
