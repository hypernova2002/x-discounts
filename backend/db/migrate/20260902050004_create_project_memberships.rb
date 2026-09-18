# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :project_memberships do
      primary_key :id
      foreign_key :project_id, :projects, null: false
      foreign_key :user_id, :users, null: false

      String :role, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:project_id, :user_id], unique: true
      index :user_id

      constraint(:valid_role) { role =~ %w[admin developer marketer viewer] }
    end
  end
end
