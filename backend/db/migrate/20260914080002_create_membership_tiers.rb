# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:membership_tiers) do
      primary_key :id
      foreign_key :membership_scheme_id, :membership_schemes, null: false
      column :name, "text", null: false
      column :rank, "integer", null: false
      column :public_id, "text", null: false
      column :created_at, "timestamptz", null: false
      column :updated_at, "timestamptz", null: false

      index [:membership_scheme_id]
      index %i[membership_scheme_id rank], unique: true, name: :membership_tiers_scheme_rank_unique
      index %i[membership_scheme_id name], unique: true, name: :membership_tiers_scheme_name_unique
      index [:public_id], unique: true, name: :membership_tiers_public_id_unique
    end
  end
end
