# frozen_string_literal: true

class MembershipTierResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :rank, :grace_period_days, :created_at, :updated_at

  attribute(:requirements_condition) { |tier| tier.requirements_condition.to_h }
  attribute(:auto_assignable) { |tier| tier.auto_assignable? }

  attribute(:membership_scheme) { |tier| { id: tier.membership_scheme.public_id, name: tier.membership_scheme.name } }
end
