# frozen_string_literal: true

module Schemas
  class LoginRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[email password],
      properties: {
        email: { type: :string },
        password: { type: :string }
      }
    )
  end
end
