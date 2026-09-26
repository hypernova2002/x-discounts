# frozen_string_literal: true

class CustomAttribute < Sequel::Model
  PUBLIC_ID_PREFIX = "attr"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project

  def validate
    super
    validates_presence [:project_id, :entity, :key, :data_type]
    validates_includes ConditionVocabulary::ENTITIES, :entity, allow_missing: true
    validates_includes ConditionVocabulary::DATA_TYPES, :data_type, allow_missing: true
    validates_utf8_length :key, max: 255
    validates_unique %i[project_id entity key] unless errors[:key]
  end
end
