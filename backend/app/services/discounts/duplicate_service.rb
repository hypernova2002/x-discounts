# frozen_string_literal: true

module Discounts
  # Clones a discount's own fields and its discount_effects, but deliberately
  # never touches coupon_codes (codes are meant to be freshly generated, not
  # shared between two discounts) or discount_stacking_compatibilities (a fresh
  # discount has no established compatibility relationships yet). `campaign:`
  # lets Campaigns::DuplicateService point cloned discounts at the new campaign
  # instead of the source discount's own.
  class DuplicateService
    def initialize(discount:, campaign: nil)
      @discount = discount
      @campaign = campaign || @discount.campaign
    end

    def call
      Discount.db.transaction do
        duplicate = Discount.new(
          project_id: @discount.project_id,
          campaign_id: @campaign.id,
          kind: @discount.kind,
          name: "Copy of #{@discount.name}",
          key: duplicate_key,
          stackable: @discount.stackable,
          refundable: @discount.refundable,
          enabled: @discount.enabled,
          eligibility_condition: @discount.eligibility_condition&.to_h,
          kind_config: @discount.kind_config.to_h,
          max_redemptions: @discount.max_redemptions,
          max_redemptions_per_customer: @discount.max_redemptions_per_customer,
          max_redemptions_per_day: @discount.max_redemptions_per_day,
          max_redemption_amount: @discount.max_redemption_amount,
          max_redemption_amount_per_day: @discount.max_redemption_amount_per_day,
          max_redemption_amount_per_customer: @discount.max_redemption_amount_per_customer
        )
        duplicate.save

        @discount.discount_effects.each do |effect|
          duplicate.add_discount_effect(
            effect_type: effect.effect_type,
            scope: effect.scope,
            target_condition: effect.target_condition&.to_h,
            config: effect.config.to_h
          )
        end

        duplicate
      end
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def duplicate_key
      base = "#{@discount.key}-copy"
      candidate = base
      suffix = 2
      while Discount.where(project_id: @discount.project_id, key: candidate).first
        candidate = "#{base}-#{suffix}"
        suffix += 1
      end
      candidate
    end
  end
end
