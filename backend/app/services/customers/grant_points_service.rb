# frozen_string_literal: true

module Customers
  class GrantPointsService
    def initialize(customer:, points:, expires_at: nil, reason: nil, performed_by: nil)
      @customer = customer
      @points = points.to_i
      @expires_at = expires_at
      @reason = reason
      @performed_by = performed_by
    end

    def call
      raise ValidationError.new(details: [{ field: "points", message: "must be a positive number" }]) unless @points.positive?

      lot = nil
      Customer.db.transaction do
        customer = @customer.lock!
        lot = customer.add_loyalty_point_lot(
          points: @points,
          earned_at: Time.now.utc,
          expires_at: @expires_at,
          source: "manual_grant",
          reason: @reason,
          performed_by_user: @performed_by
        )
      end
      lot
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
