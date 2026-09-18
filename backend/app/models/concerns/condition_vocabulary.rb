# frozen_string_literal: true

# Single source of truth for the condition-tree vocabulary — shared between
# ConditionTreeValidatable (persisted model validation) and ConditionNode (request
# model validation), which each need the same lists but validate at different layers.
module ConditionVocabulary
  ENTITIES = %w[cart line_item customer].freeze
  GROUP_OPERATORS = %w[and or not].freeze

  # Operators that don't take a value — presence/absence checks apply regardless of
  # a custom attribute's declared data type, so they're valid for every type below.
  NULLARY_OPERATORS = %w[is_null is_not_null].freeze

  LEAF_OPERATORS = (%w[eq ne gt gte lt lte in not_in contains] + NULLARY_OPERATORS).freeze

  OPERATORS_BY_DATA_TYPE = {
    "string" => %w[eq ne in not_in contains] + NULLARY_OPERATORS,
    "number" => %w[eq ne gt gte lt lte in not_in] + NULLARY_OPERATORS,
    "date" => %w[eq ne gt gte lt lte] + NULLARY_OPERATORS,
    "boolean" => %w[eq ne] + NULLARY_OPERATORS
  }.transform_values(&:freeze).freeze

  DATA_TYPES = OPERATORS_BY_DATA_TYPE.keys.freeze
end
