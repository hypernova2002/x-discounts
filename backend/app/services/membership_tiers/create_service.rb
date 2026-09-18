# frozen_string_literal: true

module MembershipTiers
  class CreateService
    def initialize(scheme:, request:)
      @scheme = scheme
      @request = request
    end

    def call
      tier = MembershipTier.new(
        membership_scheme: @scheme,
        name: @request.name,
        rank: @request.rank,
        requirements_condition: @request.requirements_condition&.to_h || {},
        grace_period_days: @request.grace_period_days
      )
      tier.save
      tier
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
