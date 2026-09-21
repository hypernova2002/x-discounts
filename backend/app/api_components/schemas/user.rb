# frozen_string_literal: true

module Schemas
  class User
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        email: { type: :string },
        otp_enabled: { type: :boolean, readOnly: true },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
