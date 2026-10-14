# frozen_string_literal: true

module Schemas
  class CouponCode
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        code: { type: :string },
        max_redemptions: { type: :integer },
        created_at: { type: :string, format: "date-time", readOnly: true },
        redemption_count: { type: :integer, readOnly: true },
        remaining_redemptions: { type: :integer, readOnly: true },
        customer: {
          type: :object,
          nullable: true,
          properties: {
            id: { type: :string },
            external_id: { type: :string },
            name: { type: :string, nullable: true }
          }
        }
      }
    )
  end
end
