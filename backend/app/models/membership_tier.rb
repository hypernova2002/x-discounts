# frozen_string_literal: true

class MembershipTier < Sequel::Model
  PUBLIC_ID_PREFIX = "mtier"

  include ConditionTreeValidatable
  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :membership_scheme

  def validate
    super
    validates_presence %i[membership_scheme_id name rank]
    validates_utf8_length :name, max: 1000
    validates_unique %i[membership_scheme_id name] unless errors[:name]
    validates_bounded_number :rank, min: 0, max: 10_000, integer_only: true
    validates_unique %i[membership_scheme_id rank] unless errors[:rank]
    validates_bounded_number :grace_period_days, min: 1, max: 10_000, integer_only: true

    if requirements_condition && !requirements_condition.empty?
      condition_errors = []
      valid_condition_tree?(requirements_condition, condition_errors)
      condition_errors.each { |msg| errors.add(:requirements_condition, msg) }
    end
  end

  # A blank condition deliberately does NOT mean "everyone qualifies" here (unlike
  # discount eligibility) — it means this tier opts out of automatic assignment
  # entirely, so pre-existing/manually-managed tiers aren't suddenly swept into by
  # Memberships::EvaluateCustomerService the moment this feature ships.
  def auto_assignable?
    requirements_condition.present? && !requirements_condition.to_h.empty?
  end
end
