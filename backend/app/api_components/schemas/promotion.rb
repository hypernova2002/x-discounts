# frozen_string_literal: true

module Schemas
  class Promotion
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        active_from: { type: :string, format: "date-time" },
        active_until: { type: [:string, :null], format: "date-time" }
      }
    )
  end
end
