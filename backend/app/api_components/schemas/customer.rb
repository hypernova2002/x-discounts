# frozen_string_literal: true

module Schemas
  class Customer
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        external_id: { type: :string },
        name: { type: :string, nullable: true },
        email: { type: :string, nullable: true },
        phone_number: { type: :string, nullable: true },
        country: { type: :string, nullable: true },
        date_of_birth: { type: :string, format: "date", nullable: true },
        marketing_opt_in: { type: :boolean },
        metadata: { type: :object },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
