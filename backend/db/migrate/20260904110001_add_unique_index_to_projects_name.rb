# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:projects) do
      add_index %i[account_id name], unique: true, name: :projects_account_id_name_unique
    end
  end
end
