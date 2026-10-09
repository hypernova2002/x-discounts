# frozen_string_literal: true

module Schemas
  class ExportCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[export_type],
      properties: {
        export_type: { type: :string, enum: ::Export::TYPES },
        params: { type: :object }
      }
    )
  end
end
