# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:discount_effects) do
      drop_constraint :valid_effect_type
      add_constraint(:valid_effect_type) do
        effect_type =~ %w[percentage_off fixed_amount_off free_item points_per_currency points_flat points_per_item points_multiplier]
      end
    end
  end

  down do
    alter_table(:discount_effects) do
      drop_constraint :valid_effect_type
      add_constraint(:valid_effect_type) { effect_type =~ %w[percentage_off fixed_amount_off free_item] }
    end
  end
end
