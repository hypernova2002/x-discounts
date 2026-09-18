# frozen_string_literal: true

module Schemas
  class CustomAttribute
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        entity: { type: :string, enum: ConditionVocabulary::ENTITIES },
        key: { type: :string },
        data_type: { type: :string, enum: ConditionVocabulary::DATA_TYPES },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
