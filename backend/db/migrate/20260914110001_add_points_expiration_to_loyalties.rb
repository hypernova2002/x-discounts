# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:loyalties) do
      # Nullable — null means points from this discount never expire.
      add_column :points_expire_after_days, "integer"
    end
  end
end
