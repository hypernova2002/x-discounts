# frozen_string_literal: true

module MembershipTiers
  class UpdateService
    def initialize(tier:, request:)
      @tier = tier
      @request = request
    end

    def call
      @tier.name = @request.name if @request.attributes.key?(:name)
      @tier.rank = @request.rank if @request.attributes.key?(:rank)
      @tier.requirements_condition = @request.requirements_condition&.to_h || {} if @request.attributes.key?(:requirements_condition)
      @tier.grace_period_days = @request.grace_period_days if @request.attributes.key?(:grace_period_days)
      @tier.save
      @tier
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
