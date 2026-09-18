# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :discounts do
      primary_key :id
      foreign_key :project_id, :projects, null: false

      String :kind, null: false
      String :name, null: false
      TrueClass :stackable, null: false, default: false
      column :eligibility_condition, :jsonb, null: false, default: "{}"

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :project_id
      constraint(:valid_kind) { kind =~ %w[promotion coupon] }
    end
  end
end
