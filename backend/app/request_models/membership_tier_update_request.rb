# frozen_string_literal: true

class MembershipTierUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :rank, JsonModel::Types::Integer
  attribute? :requirements_condition, ConditionNode.optional
  attribute? :grace_period_days, JsonModel::Types::Integer.constrained(gt: 0).optional
end
