# frozen_string_literal: true

module Schemas
  # The plain hash Refunds::CreateService returns, shared by the order_discount
  # and points_redemption refund endpoints.
  class RefundResult
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        amount_off: { type: :number, nullable: true },
        points: { type: :integer, nullable: true },
        refunded_at: { type: :string, format: "date-time" }
      }
    )
  end
end
