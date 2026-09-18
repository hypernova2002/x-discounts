# frozen_string_literal: true

module Schemas
  # Matches ApiError#to_response — the single shape every error response in the
  # API uses, whatever raised it (see app/errors/).
  class Error
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        error: {
          type: :object,
          properties: {
            code: { type: :string, description: "See ErrorCodes::REGISTRY for the full list" },
            message: { type: :string },
            details: {
              type: :array,
              description: "Field-specific problems, if any. Empty for errors that aren't field-specific.",
              items: {
                type: :object,
                properties: {
                  field: { type: :string },
                  message: { type: :string }
                }
              }
            }
          }
        }
      }
    )
  end
end
