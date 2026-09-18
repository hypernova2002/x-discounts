# frozen_string_literal: true

module Schemas
  class DiscountCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[kind key name],
      properties: {
        kind: { type: :string, enum: %w[promotion coupon] },
        key: { type: :string, description: "Unique per project. Letters, numbers, underscores, hyphens, periods." },
        name: { type: :string },
        stackable: { type: :boolean, default: false },
        eligibility_condition: ConditionNode,
        promotion: {
          type: :object,
          description: "Required when kind = promotion",
          required: %w[active_from],
          properties: {
            active_from: { type: :string, format: "date-time" },
            active_until: { type: :string, format: "date-time" }
          }
        },
        coupon: {
          type: :object,
          description: "Required when kind = coupon",
          required: %w[code],
          properties: {
            code: { type: :string },
            issued_from: { type: :string, format: "date-time" },
            issued_until: { type: :string, format: "date-time" },
            valid_from: { type: :string, format: "date-time" },
            valid_until: { type: :string, format: "date-time" }
          }
        },
        effects: {
          type: :array,
          items: {
            type: :object,
            required: %w[effect_type scope config],
            properties: {
              effect_type: { type: :string, enum: %w[percentage_off fixed_amount_off free_item] },
              scope: { type: :string, enum: %w[cart line_item] },
              target_condition: { description: "Required when scope = line_item", anyOf: [ConditionNode, { type: :null }] },
              config: {
                type: :object,
                description: "percentage_off -> {percentage}, fixed_amount_off -> {amount, currency}, " \
                              "free_item -> {buy_quantity, get_quantity, repeatable, buy_condition, get_condition}"
              }
            }
          }
        },
        max_redemptions: { type: :integer, description: "Applies to promotions and coupons alike" },
        max_redemptions_per_customer: { type: :integer },
        max_redemptions_per_day: { type: :integer },
        max_redemption_amount: { type: :number, description: "Total across the discount's whole lifetime" },
        max_redemption_amount_per_day: { type: :number },
        max_redemption_amount_per_customer: { type: :number }
      }
    )
  end
end
