# frozen_string_literal: true

module Schemas
  class ApiKeyCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[user_id role name],
      properties: {
        user_id: { type: :string },
        role: { type: :string, enum: %w[admin developer marketer viewer] },
        name: { type: :string }
      }
    )
  end
end
