# frozen_string_literal: true

module Schemas
  class Export
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        export_type: { type: :string, enum: ::Export::TYPES },
        status: { type: :string, enum: ::Export::STATUSES },
        filename: { type: :string, nullable: true },
        byte_size: { type: :integer, nullable: true },
        error_message: { type: :string, nullable: true },
        created_at: { type: :string, format: "date-time", readOnly: true },
        completed_at: { type: :string, format: "date-time", nullable: true, readOnly: true },
        requested_by: { type: :string, nullable: true, readOnly: true }
      }
    )
  end
end
