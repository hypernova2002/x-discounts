# frozen_string_literal: true

# A node in an eligibility/target condition tree: either a group
# ({operator: and|or|not, conditions: [...]}) or a leaf
# ({entity:, key:, operator:, value:}). Self-referential — a group's
# `conditions` are themselves ConditionNodes, arbitrarily deep.
class ConditionNode < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :operator, JsonModel::Types::String.optional
  attribute? :entity, JsonModel::Types::String.optional
  attribute? :key, JsonModel::Types::String.optional
  attribute? :value, JsonModel::Types::Any.optional
  # Only meaningful for a handful of reserved, aggregate "customer" keys (see
  # Memberships::TierEvaluator) — e.g. "total_spent" over the last N days rather than
  # lifetime. Absent/null means lifetime. Harmless and unused everywhere else a
  # condition tree appears (discount eligibility/effect target conditions).
  attribute? :window_days, JsonModel::Types::Integer.optional

  def group?
    ConditionVocabulary::GROUP_OPERATORS.include?(operator)
  end

  def leaf?
    ConditionVocabulary::LEAF_OPERATORS.include?(operator)
  end

  # Struct-level typing only guarantees shape (strings are strings, etc.) — this
  # checks the domain rules that differ between group vs. leaf nodes and can't be
  # expressed as a single attribute type. Appends messages to errors_list.
  def validate(errors_list, path = "root")
    if group?
      validate_group(errors_list, path)
    elsif leaf?
      validate_leaf(errors_list, path)
    else
      all_operators = ConditionVocabulary::GROUP_OPERATORS + ConditionVocabulary::LEAF_OPERATORS
      errors_list << "#{path}: operator must be one of #{all_operators.join(', ')}"
      false
    end
  end

  private

  def validate_group(errors_list, path)
    unless conditions.is_a?(::Array) && conditions.any?
      errors_list << "#{path}: group operator '#{operator}' requires a non-empty 'conditions' array"
      return false
    end

    if operator == "not" && conditions.size != 1
      errors_list << "#{path}: 'not' requires exactly one condition"
      return false
    end

    conditions.each_with_index.map { |c, i| c.validate(errors_list, "#{path}.conditions[#{i}]") }.all?
  end

  def validate_leaf(errors_list, path)
    ok = true

    unless ConditionVocabulary::ENTITIES.include?(entity)
      errors_list << "#{path}: entity must be one of #{ConditionVocabulary::ENTITIES.join(', ')}"
      ok = false
    end

    unless key.is_a?(::String) && !key.empty?
      errors_list << "#{path}: key must be a non-empty string"
      ok = false
    end

    if value.nil? && !ConditionVocabulary::NULLARY_OPERATORS.include?(operator)
      errors_list << "#{path}: value is required"
      ok = false
    end

    ok
  end
end

ConditionNode.attribute?(:conditions, JsonModel::Types::Array.of(ConditionNode).optional)
