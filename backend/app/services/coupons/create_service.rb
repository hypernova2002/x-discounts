# frozen_string_literal: true

module Coupons
  class CreateService
    def initialize(project:, request:, campaign:)
      @project = project
      @request = request
      @campaign = campaign
    end

    def call
      discount = build_discount

      Discount.db.transaction do
        discount.save
        save_effects(discount, @request.effects || [])
        generate_initial_codes(discount) if code_config_given?
      end

      discount.refresh
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.from_model(discount) unless discount.valid?

      raise
    end

    private

    def build_discount
      Discount.new(
        kind: "coupon",
        key: @request.key.presence || Discounts::KeyGenerator.generate(name: @request.name, project: @project),
        name: @request.name,
        campaign: @campaign,
        stackable: @request.stackable,
        refundable: @request.refundable,
        enabled: @request.enabled,
        eligibility_condition: @request.eligibility_condition&.to_h || {},
        kind_config: coupon_kind_config,
        max_redemptions: @request.max_redemptions,
        max_redemptions_per_customer: @request.max_redemptions_per_customer,
        max_redemptions_per_day: @request.max_redemptions_per_day,
        max_redemption_amount: @request.max_redemption_amount,
        max_redemption_amount_per_day: @request.max_redemption_amount_per_day,
        max_redemption_amount_per_customer: @request.max_redemption_amount_per_customer,
        project: @project
      )
    end

    def coupon_kind_config
      {
        issued_from: @request.coupon.issued_from,
        issued_until: @request.coupon.issued_until,
        valid_from: @request.coupon.valid_from,
        valid_until: @request.coupon.valid_until
      }.compact
    end

    def code_config_given?
      @request.coupon.code.present? || @request.coupon.count.present? || @request.coupon.customer_ids.present?
    end

    # Same shape as CouponCodeGenerateRequest, so this just hands it straight to the
    # same service the standalone "add codes" endpoint uses.
    def generate_initial_codes(discount)
      code_request = CouponCodeGenerateRequest.new(
        code: @request.coupon.code,
        count: @request.coupon.count,
        customer_ids: @request.coupon.customer_ids,
        customer_id: @request.coupon.customer_id,
        prefix: @request.coupon.prefix,
        suffix: @request.coupon.suffix,
        max_redemptions: @request.coupon.max_redemptions
      )
      CouponCodes::GenerateService.new(discount: discount, project: @project, request: code_request).call
    end

    def save_effects(discount, effect_requests)
      effect_requests.each_with_index do |effect_req, i|
        attrs = {
          effect_type: effect_req.effect_type,
          scope: effect_req.scope,
          target_condition: effect_req.target_condition&.to_h,
          config: effect_req.typed_config.to_h
        }
        save_effect(discount, DiscountEffect.new(attrs), i)
      end
    end

    def save_effect(discount, effect, index)
      discount.add_discount_effect(effect)
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model, prefix: "effects[#{index}]")
    end
  end
end
