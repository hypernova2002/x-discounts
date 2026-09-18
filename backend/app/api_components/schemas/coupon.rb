# frozen_string_literal: true

module Schemas
  class Coupon
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        code: { type: :string },
        issued_from: { type: [:string, :null], format: "date-time" },
        issued_until: { type: [:string, :null], format: "date-time" },
        valid_from: { type: [:string, :null], format: "date-time" },
        valid_until: { type: [:string, :null], format: "date-time" }
      }
    )
  end
end
