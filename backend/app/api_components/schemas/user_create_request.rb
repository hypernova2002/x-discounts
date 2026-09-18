# frozen_string_literal: true

module Schemas
  class UserCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[name email],
      properties: {
        name: { type: :string },
        email: { type: :string }
      }
    )
  end
end
