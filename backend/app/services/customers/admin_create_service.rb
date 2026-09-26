# frozen_string_literal: true

module Customers
  # Strict create, unlike the upsert-by-external_id Customers::CreateService used
  # by the public checkout/redeem flow — an admin explicitly creating a customer
  # should get a clear "already taken" error on a duplicate external_id, not a
  # silent update of an existing record.
  class AdminCreateService
    def initialize(project:, request:)
      @project = project
      @request = request
    end

    def call
      customer = Customer.new(
        project: @project,
        external_id: @request.external_id,
        name: @request.name,
        email: @request.email,
        phone_number: @request.phone_number,
        country: @request.country,
        date_of_birth: @request.date_of_birth,
        marketing_opt_in: @request.marketing_opt_in || false
      )
      customer.save
      customer
    rescue Sequel::ValidationFailed => e
      # Customer's own validates_unique [:project_id, :external_id] reports under the
      # joined compound key ("project_id,external_id"), which doesn't match any real
      # form field and would otherwise be silently dropped client-side — surface it
      # as a plain external_id error instead, since that's the only field an admin
      # creating a customer actually controls here.
      compound_error = e.model.errors[%i[project_id external_id]]
      if compound_error
        raise ValidationError.new(details: [{ field: "external_id", message: compound_error.first }])
      end

      raise ValidationError.from_model(e.model)
    end
  end
end
