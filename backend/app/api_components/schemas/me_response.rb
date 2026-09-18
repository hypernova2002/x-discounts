# frozen_string_literal: true

module Schemas
  class MeResponse
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        project: { anyOf: [MinimalProject, { type: :null }], description: "null until a session picks one via X-Project-Id" },
        user: MinimalUser,
        role: { type: [:string, :null], enum: ["admin", "developer", "marketer", "viewer", nil] }
      }
    )
  end
end
