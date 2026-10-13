# frozen_string_literal: true

module Customers
  class UpdateService
    def initialize(customer:, request:, membership_tier:)
      @customer = customer
      @request = request
      @membership_tier = membership_tier
    end

    def call
      if @request.attributes.key?(:membership_tier_id) && @membership_tier&.id != @customer.membership_tier_id
        @customer.change_membership_tier!(@membership_tier)
      else
        @customer.save
      end
      @customer
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
