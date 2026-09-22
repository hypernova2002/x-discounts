# frozen_string_literal: true

module Schemas
  # Matches MinimalProjectResource — what /me returns for the current project.
  class MinimalProject
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        timezone: { type: :string }
      }
    )
  end
end
