# frozen_string_literal: true

module Schemas
  # Only the create response includes this — the raw token is never retrievable again.
  class ApiKeyWithToken < ApiKey
    schema(
      properties: {
        token: { type: :string }
      }
    )
  end
end
