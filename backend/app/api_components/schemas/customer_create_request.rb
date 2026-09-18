# frozen_string_literal: true

module Schemas
  class CustomerCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[external_id],
      properties: {
        external_id: { type: :string },
        name: { type: :string },
        email: { type: :string },
        phone_number: { type: :string },
        country: { type: :string },
        date_of_birth: { type: :string, format: "date" },
        marketing_opt_in: { type: :boolean },
        metadata: { type: :object }
      }
    )
  end
end
