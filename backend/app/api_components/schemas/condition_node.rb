# frozen_string_literal: true

module Schemas
  # A node in an eligibility/target condition tree: either a group
  # (operator: and/or/not + conditions) or a leaf (entity/key/operator/value).
  # Self-referential via conditions — components/$ref make this safe, unlike
  # inline schema expansion.
  class ConditionNode
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      description: "Either a condition group (and/or/not + conditions) or a leaf condition (entity/key/operator/value).",
      properties: {
        operator: {
          type: :string,
          description: (ConditionVocabulary::GROUP_OPERATORS + ConditionVocabulary::LEAF_OPERATORS).join(" | ")
        },
        entity: { type: :string, enum: ConditionVocabulary::ENTITIES },
        key: { type: :string },
        value: { description: "Omit (or leave null) for is_null / is_not_null" },
        conditions: { type: :array, items: ConditionNode }
      }
    )
  end
end
