# frozen_string_literal: true

module Customers
  class DuplicateService
    def initialize(customer:)
      @customer = customer
    end

    def call
      duplicate = Customer.new(
        project_id: @customer.project_id,
        external_id: duplicate_external_id,
        name: @customer.name,
        email: @customer.email,
        phone_number: @customer.phone_number,
        country: @customer.country,
        date_of_birth: @customer.date_of_birth,
        marketing_opt_in: @customer.marketing_opt_in,
        membership_tier_id: @customer.membership_tier_id,
        metadata: @customer.metadata.to_h
      )
      duplicate.save
      duplicate
    rescue Sequel::ValidationFailed => e
      # Customer's validates_unique [:project_id, :external_id] reports under the
      # joined compound key, same gotcha as Customers::AdminCreateService — remap
      # to a plain external_id error in the unlikely case the uniquified value
      # still collides.
      compound_error = e.model.errors[%i[project_id external_id]]
      if compound_error
        raise ValidationError.new(details: [{ field: "external_id", message: compound_error.first }])
      end

      raise ValidationError.from_model(e.model)
    end

    private

    def duplicate_external_id
      base = "Copy of #{@customer.external_id}"
      candidate = base
      suffix = 2
      while Customer.where(project_id: @customer.project_id, external_id: candidate).first
        candidate = "#{base} (#{suffix})"
        suffix += 1
      end
      candidate
    end
  end
end
