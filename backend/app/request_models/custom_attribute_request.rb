# frozen_string_literal: true

class CustomAttributeRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :entity, JsonModel::Types::String.enum(*ConditionVocabulary::ENTITIES)
  attribute :key, JsonModel::Types::String.constrained(min_size: 1)
  attribute :data_type, JsonModel::Types::String.enum(*ConditionVocabulary::DATA_TYPES)
end
