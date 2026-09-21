# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:users) do
      add_column :otp_secret, "text"
      add_column :otp_enabled, "boolean", null: false, default: false
      add_column :otp_backup_codes, "jsonb", null: false, default: "[]"
    end

    alter_table(:accounts) do
      add_column :otp_required, "boolean", null: false, default: false
    end

    create_table :otp_challenges do
      primary_key :id
      foreign_key :user_id, :users, null: false

      String :token_digest, null: false
      DateTime :expires_at, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :user_id
      index :token_digest, unique: true
    end
  end
end
