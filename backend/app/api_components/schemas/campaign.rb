# frozen_string_literal: true

module Schemas
  class Campaign
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        enabled: { type: :boolean },
        archived: { type: :boolean },
        valid_from: { type: :string, format: "date-time", nullable: true },
        valid_until: { type: :string, format: "date-time", nullable: true },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true },
        active: { type: :boolean, readOnly: true },
        discount_kinds: { type: :array, readOnly: true, items: { type: :string, enum: %w[promotion coupon loyalty] } }
      }
    )
  end
end
