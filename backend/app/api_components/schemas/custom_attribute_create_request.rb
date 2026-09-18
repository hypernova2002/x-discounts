# frozen_string_literal: true

module Schemas
  class CustomAttributeCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[entity key data_type],
      properties: {
        entity: { type: :string, enum: ConditionVocabulary::ENTITIES },
        key: { type: :string },
        data_type: { type: :string, enum: ConditionVocabulary::DATA_TYPES }
      }
    )
  end
end
