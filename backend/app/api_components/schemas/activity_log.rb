# frozen_string_literal: true

module Schemas
  class ActivityLog
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        action: { type: :string, enum: %w[create update delete] },
        entity_type: { type: :string },
        entity_label: { type: :string },
        entity_public_id: { type: :string, nullable: true },
        actor_label: { type: :string, nullable: true },
        changes: { type: :object },
        request_id: { type: :string, nullable: true },
        created_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
