# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:refunds) do
      drop_column :reason
    end
  end
end
