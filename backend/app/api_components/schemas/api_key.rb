# frozen_string_literal: true

module Schemas
  class ApiKey
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        role: { type: :string, enum: %w[admin developer marketer viewer] },
        user_id: { type: :string },
        token_last_four: { type: :string, description: "Last 4 characters of the token, for display only" },
        last_used_at: { type: [:string, :null], format: "date-time" },
        revoked_at: { type: [:string, :null], format: "date-time" },
        created_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
