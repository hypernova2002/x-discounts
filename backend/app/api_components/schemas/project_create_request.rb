# frozen_string_literal: true

module Schemas
  class ProjectCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[name],
      properties: {
        name: { type: :string }
      }
    )
  end
end
