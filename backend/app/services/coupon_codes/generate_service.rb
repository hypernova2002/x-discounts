# frozen_string_literal: true

require "securerandom"

module CouponCodes
  # Three mutually exclusive modes (see CouponCodeGenerateRequest):
  # - code: one manual code with the exact string given, optionally customer-bound.
  # - count: N auto-generated unbound codes (anonymous bulk).
  # - customer_ids: one auto-generated, customer-bound code per given customer
  #   (personalized bulk).
  #
  # Codes are unique across the whole project, permanently, enforced by a DB
  # constraint (coupon_codes_project_id_code_unique) — not just checked here. Each
  # insert runs in its own savepoint: Postgres aborts the entire surrounding
  # transaction on any constraint violation until rolled back, so a random-generation
  # collision (or a real duplicate on the manual-code path) has to be isolated to a
  # savepoint to retry/report cleanly without losing whatever else this call already
  # created.
  class GenerateService
    CODE_LENGTH = 8
    MAX_COUNT = 5000
    MAX_ATTEMPTS = 10

    def initialize(discount:, project:, request:)
      @discount = discount
      @project = project
      @request = request
    end

    def call
      validate_mode!

      codes = []
      Discount.db.transaction do
        codes = @request.code.present? ? [create_manual_code] : create_generated_codes
      end
      codes
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def validate_mode!
      modes_given = [@request.code.present?, @request.count.present?, @request.customer_ids.present?].count(true)
      if modes_given != 1
        raise ValidationError.new(details: [{ field: "base", message: "specify exactly one of code, count, or customer_ids" }])
      end

      if @request.code.present? && (@request.prefix.present? || @request.suffix.present?)
        raise ValidationError.new(details: [{ field: "base", message: "prefix/suffix don't apply when specifying an exact code" }])
      end

      return unless @request.count.present?
      return if @request.count.between?(1, MAX_COUNT)

      raise ValidationError.new(details: [{ field: "count", message: "must be between 1 and #{MAX_COUNT}" }])
    end

    def create_manual_code
      Discount.db.transaction(savepoint: true) do
        CouponCode.create(
          discount: @discount, project: @project, customer: resolve_single_customer,
          code: @request.code, max_redemptions: @request.max_redemptions
        )
      end
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.new(details: [{ field: "code", message: "is already in use in this project" }])
    end

    def resolve_single_customer
      return nil unless @request.customer_id

      customer = Customer.first(project_id: @project.id, public_id: @request.customer_id)
      raise ValidationError.new(details: [{ field: "customer_id", message: "does not refer to an existing customer" }]) unless customer

      customer
    end

    def create_generated_codes
      customers = resolve_customers
      targets = customers || Array.new(@request.count)
      targets.map { |customer| create_code(customer) }
    end

    def resolve_customers
      return nil unless @request.customer_ids

      @request.customer_ids.map do |public_id|
        customer = Customer.first(project_id: @project.id, public_id: public_id)
        unless customer
          raise ValidationError.new(details: [{ field: "customer_ids", message: "#{public_id} does not refer to an existing customer" }])
        end

        customer
      end
    end

    def create_code(customer)
      attempts = 0
      begin
        attempts += 1
        Discount.db.transaction(savepoint: true) do
          CouponCode.create(
            discount: @discount, project: @project, customer: customer,
            code: build_candidate, max_redemptions: @request.max_redemptions
          )
        end
      rescue Sequel::UniqueConstraintViolation
        retry if attempts < MAX_ATTEMPTS
        raise ValidationError.new(details: [{ field: "base", message: "could not generate a unique code — try again" }])
      end
    end

    def build_candidate
      parts = [@request.prefix, SecureRandom.alphanumeric(CODE_LENGTH).upcase, @request.suffix].compact
      parts.join("-")
    end
  end
end
