# frozen_string_literal: true

module Schemas
  class MembershipScheme
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true },
        tiers: { type: :array, readOnly: true, items: { type: :object } }
      }
    )
  end
end
