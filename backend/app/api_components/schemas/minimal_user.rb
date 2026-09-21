# frozen_string_literal: true

module Schemas
  # Matches MinimalUserResource — what signup/login return, no timestamps.
  class MinimalUser
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        email: { type: :string },
        otp_enabled: { type: :boolean, readOnly: true }
      }
    )
  end
end
