# frozen_string_literal: true

module Schemas
  class DiscountValidationResponse
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        applicable_discounts: {
          type: :array,
          items: {
            type: :object,
            properties: {
              discount_id: { type: :string },
              kind: { type: :string, enum: %w[promotion coupon] },
              key: { type: :string },
              name: { type: :string },
              effect_type: { type: :string, enum: %w[percentage_off fixed_amount_off free_item] },
              amount_off: { type: :number, description: "Present for percentage_off / fixed_amount_off" },
              free_items: {
                type: :array,
                description: "Present for free_item",
                items: { type: :object, properties: { sku: { type: :string }, quantity: { type: :integer } } }
              }
            }
          }
        },
        total_amount_off: { type: :number },
        coupon: {
          type: :object,
          nullable: true,
          description: "Present only when a coupon_code was submitted",
          properties: {
            code: { type: :string },
            valid: { type: :boolean },
            reason: { type: :string, nullable: true }
          }
        }
      }
    )
  end
end
