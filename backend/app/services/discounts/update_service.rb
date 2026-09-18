# frozen_string_literal: true

module Discounts
  # Routes to the kind-specific service based on the already-typed request — the
  # controller picked PromotionDiscountUpdateRequest or CouponDiscountUpdateRequest
  # via DiscountUpdateRequest.build, keyed off the existing discount's kind.
  class UpdateService
    def initialize(discount:, request:, campaign: nil)
      @discount = discount
      @request = request
      @campaign = campaign
    end

    def call
      case @request
      when CouponDiscountUpdateRequest
        Coupons::UpdateService.new(discount: @discount, request: @request, campaign: @campaign).call
      when PromotionDiscountUpdateRequest
        Promotions::UpdateService.new(discount: @discount, request: @request, campaign: @campaign).call
      when LoyaltyDiscountUpdateRequest
        Loyalties::UpdateService.new(discount: @discount, request: @request, campaign: @campaign).call
      end
    end
  end
end
