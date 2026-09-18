# frozen_string_literal: true

module Schemas
  class Order
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        customer_id: { type: :string, readOnly: true },
        total_amount: { type: :number, readOnly: true },
        total_discount_amount: { type: :number, readOnly: true },
        created_at: { type: :string, format: "date-time", readOnly: true },
        line_items: {
          type: :array,
          items: {
            type: :object,
            properties: {
              sku: { type: :string },
              quantity: { type: :integer },
              unit_price: { type: :number },
              metadata: { type: :object }
            }
          }
        },
        discounts: {
          type: :array,
          items: {
            type: :object,
            properties: {
              discount_id: { type: :string, nullable: true },
              kind: { type: :string, enum: %w[promotion coupon] },
              discount_key: { type: :string },
              discount_name: { type: :string },
              effect_type: { type: :string, enum: %w[percentage_off fixed_amount_off free_item] },
              amount_off: { type: :number, nullable: true },
              free_items: { type: :array, nullable: true, items: { type: :object } }
            }
          }
        },
        coupon: {
          type: :object,
          nullable: true,
          properties: { code: { type: :string }, valid: { type: :boolean }, reason: { type: :string, nullable: true } }
        }
      }
    )
  end
end
