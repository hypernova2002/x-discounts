# frozen_string_literal: true

module Schemas
  class ProjectMembership
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        project_id: { type: :string },
        user_id: { type: :string },
        role: { type: :string, enum: %w[admin developer marketer viewer] },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
