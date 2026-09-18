# frozen_string_literal: true

module Schemas
  class DiscountEffect
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        effect_type: { type: :string, enum: %w[percentage_off fixed_amount_off free_item] },
        scope: { type: :string, enum: %w[cart line_item] },
        target_condition: { anyOf: [ConditionNode, { type: :null }] },
        config: {
          type: :object,
          description: "Shape depends on effect_type: percentage_off -> {percentage}, " \
                        "fixed_amount_off -> {amount, currency}, " \
                        "free_item -> {buy_quantity, get_quantity, repeatable, buy_condition, get_condition}"
        }
      }
    )
  end
end
