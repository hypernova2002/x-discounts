# frozen_string_literal: true

module Schemas
  class SignupRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[account_name name email password password_confirmation],
      properties: {
        account_name: { type: :string, description: "Creates a new account, with this user as its first admin" },
        name: { type: :string },
        email: { type: :string },
        password: { type: :string, minLength: 8 },
        password_confirmation: { type: :string }
      }
    )
  end
end
