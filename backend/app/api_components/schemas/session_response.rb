# frozen_string_literal: true

module Schemas
  # Returned by both signup and login.
  class SessionResponse
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        token: { type: :string, description: "sess_... — send as Authorization: Bearer <token>" },
        user: MinimalUser
      }
    )
  end
end
