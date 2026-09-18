# frozen_string_literal: true

module ConditionTreeValidatable
  # Validates a condition tree of the shape:
  #   { "operator" => "and" | "or" | "not", "conditions" => [<node>, ...] }
  #   { "entity" => "cart" | "line_item" | "customer", "key" => String, "operator" => <leaf op>, "value" => any }
  # Appends human-readable messages to errors_list and returns whether the node is valid.
  def valid_condition_tree?(node, errors_list, path = "root")
    # Sequel's JSONBHash/JSONHash wrap via DelegateClass(Hash), not true Hash
    # subclasses, so normalize before checking — is_a?(Hash) would be false.
    node = node.to_h if node.respond_to?(:to_h) && !node.is_a?(Hash)

    unless node.is_a?(Hash)
      errors_list << "#{path}: must be an object"
      return false
    end

    # Accepts either string keys (JSONB round-trip) or symbol keys (request
    # models' Dry::Struct#to_h output).
    node = node.stringify_keys

    if ConditionVocabulary::GROUP_OPERATORS.include?(node["operator"])
      validate_group_node(node, errors_list, path)
    elsif node.key?("entity") || node.key?("key") || node.key?("value")
      validate_leaf_node(node, errors_list, path)
    else
      errors_list << "#{path}: must be a condition group (operator: and/or/not) or a leaf condition (entity/key/operator/value)"
      false
    end
  end

  private

  def validate_group_node(node, errors_list, path)
    conditions = node["conditions"]
    unless conditions.is_a?(Array) && conditions.any?
      errors_list << "#{path}: group operator '#{node['operator']}' requires a non-empty 'conditions' array"
      return false
    end

    if node["operator"] == "not" && conditions.size != 1
      errors_list << "#{path}: 'not' requires exactly one condition"
      return false
    end

    conditions.each_with_index.map { |c, i| valid_condition_tree?(c, errors_list, "#{path}.conditions[#{i}]") }.all?
  end

  def validate_leaf_node(node, errors_list, path)
    ok = true

    unless ConditionVocabulary::ENTITIES.include?(node["entity"])
      errors_list << "#{path}: entity must be one of #{ConditionVocabulary::ENTITIES.join(', ')}"
      ok = false
    end

    unless node["key"].is_a?(String) && !node["key"].empty?
      errors_list << "#{path}: key must be a non-empty string"
      ok = false
    end

    unless ConditionVocabulary::LEAF_OPERATORS.include?(node["operator"])
      errors_list << "#{path}: operator must be one of #{ConditionVocabulary::LEAF_OPERATORS.join(', ')}"
      ok = false
    end

    unless ConditionVocabulary::NULLARY_OPERATORS.include?(node["operator"]) || node.key?("value")
      errors_list << "#{path}: value is required"
      ok = false
    end

    ok
  end
end
