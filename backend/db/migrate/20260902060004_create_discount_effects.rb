# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :discount_effects do
      primary_key :id
      foreign_key :discount_id, :discounts, null: false

      String :effect_type, null: false
      String :scope, null: false
      # Only used when scope = "line_item" — selects which line items the effect touches.
      column :target_condition, :jsonb
      # Type-specific fields: {percentage:} | {amount:, currency:} |
      # {buy_condition:, buy_quantity:, get_condition:, get_quantity:, repeatable:}
      column :config, :jsonb, null: false, default: "{}"

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :discount_id
      constraint(:valid_effect_type) { effect_type =~ %w[percentage_off fixed_amount_off free_item] }
      constraint(:valid_scope) { scope =~ %w[cart line_item] }
    end
  end
end
