# frozen_string_literal: true

class FreeItemConfigRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :buy_quantity, JsonModel::Types::Integer.constrained(gt: 0)
  attribute :get_quantity, JsonModel::Types::Integer.constrained(gt: 0)
  attribute :repeatable, JsonModel::Types::Bool
  attribute :buy_condition, ConditionNode
  attribute :get_condition, ConditionNode
end
