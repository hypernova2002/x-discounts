# frozen_string_literal: true

module Promotions
  class UpdateService
    def initialize(discount:, request:, campaign: nil)
      @discount = discount
      @request = request
      @campaign = campaign
    end

    def call
      Discount.db.transaction do
        @discount.set(discount_base_attrs)
        @discount.save

        replace_effects if @request.attributes.key?(:effects)
      end

      @discount.refresh
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.from_model(@discount) unless @discount.valid?

      raise
    end

    private

    def discount_base_attrs
      attrs = {}
      attrs[:key] = @request.key if @request.attributes.key?(:key)
      attrs[:name] = @request.name if @request.attributes.key?(:name)
      attrs[:campaign] = @campaign if @request.attributes.key?(:campaign_id)
      attrs[:stackable] = @request.stackable if @request.attributes.key?(:stackable)
      attrs[:refundable] = @request.refundable if @request.attributes.key?(:refundable)
      attrs[:enabled] = @request.enabled if @request.attributes.key?(:enabled)
      attrs[:eligibility_condition] = @request.eligibility_condition&.to_h if @request.attributes.key?(:eligibility_condition)
      if @request.attributes.key?(:promotion)
        attrs[:kind_config] = { active_from: @request.promotion.active_from, active_until: @request.promotion.active_until }.compact
      end
      attrs[:max_redemptions] = @request.max_redemptions if @request.attributes.key?(:max_redemptions)
      if @request.attributes.key?(:max_redemptions_per_customer)
        attrs[:max_redemptions_per_customer] = @request.max_redemptions_per_customer
      end
      attrs[:max_redemptions_per_day] = @request.max_redemptions_per_day if @request.attributes.key?(:max_redemptions_per_day)
      attrs[:max_redemption_amount] = @request.max_redemption_amount if @request.attributes.key?(:max_redemption_amount)
      if @request.attributes.key?(:max_redemption_amount_per_day)
        attrs[:max_redemption_amount_per_day] = @request.max_redemption_amount_per_day
      end
      if @request.attributes.key?(:max_redemption_amount_per_customer)
        attrs[:max_redemption_amount_per_customer] = @request.max_redemption_amount_per_customer
      end
      attrs
    end

    def replace_effects
      @discount.discount_effects.each(&:destroy)
      save_effects
    end

    def save_effects
      (@request.effects || []).each_with_index do |effect_req, i|
        attrs = {
          effect_type: effect_req.effect_type,
          scope: effect_req.scope,
          target_condition: effect_req.target_condition&.to_h,
          config: effect_req.typed_config.to_h
        }
        save_effect(DiscountEffect.new(attrs), i)
      end
    end

    def save_effect(effect, index)
      @discount.add_discount_effect(effect)
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model, prefix: "effects[#{index}]")
    end
  end
end
