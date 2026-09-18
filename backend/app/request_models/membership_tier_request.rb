# frozen_string_literal: true

class MembershipTierRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute :rank, JsonModel::Types::Integer
  # Blank/omitted means this tier is never auto-assigned (see MembershipTier#auto_assignable?).
  attribute? :requirements_condition, ConditionNode.optional
  # Blank/omitted means no grace period — demotion out of this tier applies immediately.
  attribute? :grace_period_days, JsonModel::Types::Integer.constrained(gt: 0).optional
end
