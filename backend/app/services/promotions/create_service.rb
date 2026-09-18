# frozen_string_literal: true

module Promotions
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
        kind: "promotion",
        key: @request.key.presence || Discounts::KeyGenerator.generate(name: @request.name, project: @project),
        name: @request.name,
        campaign: @campaign,
        stackable: @request.stackable,
        refundable: @request.refundable,
        enabled: @request.enabled,
        eligibility_condition: @request.eligibility_condition&.to_h || {},
        kind_config: { active_from: @request.promotion.active_from, active_until: @request.promotion.active_until }.compact,
        max_redemptions: @request.max_redemptions,
        max_redemptions_per_customer: @request.max_redemptions_per_customer,
        max_redemptions_per_day: @request.max_redemptions_per_day,
        max_redemption_amount: @request.max_redemption_amount,
        max_redemption_amount_per_day: @request.max_redemption_amount_per_day,
        max_redemption_amount_per_customer: @request.max_redemption_amount_per_customer,
        project: @project
      )
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
