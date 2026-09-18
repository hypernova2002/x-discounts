# frozen_string_literal: true

module Schemas
  class DiscountValidationRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        cart: {
          type: :object,
          description: "Arbitrary keys matched against cart custom attributes. total and item_count are " \
                        "reserved — always computed from line_items, not read from this object."
        },
        line_items: {
          type: :array,
          items: {
            type: :object,
            required: %w[sku quantity unit_price],
            properties: {
              sku: { type: :string },
              quantity: { type: :number },
              unit_price: { type: :number },
              additionalProperties: true
            }
          }
        },
        customer: {
          type: :object,
          description: "external_id plus arbitrary keys matched against customer custom attributes.",
          properties: { external_id: { type: :string } }
        },
        coupon_code: { type: :string },
        as_of: {
          type: :string,
          format: "date-time",
          description: "Validate-only: preview against this time instead of now. Ignored by /discounts/redeem."
        }
      }
    )
  end
end
