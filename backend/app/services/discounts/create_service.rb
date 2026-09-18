# frozen_string_literal: true

module Discounts
  # Routes to the kind-specific service based on the already-typed request — the
  # controller picked PromotionDiscountRequest or CouponDiscountRequest via
  # DiscountRequest.build, so no branching on raw kind strings happens here.
  class CreateService
    def initialize(project:, request:, campaign:)
      @project = project
      @request = request
      @campaign = campaign
    end

    def call
      case @request
      when CouponDiscountRequest
        Coupons::CreateService.new(project: @project, request: @request, campaign: @campaign).call
      when PromotionDiscountRequest
        Promotions::CreateService.new(project: @project, request: @request, campaign: @campaign).call
      when LoyaltyDiscountRequest
        Loyalties::CreateService.new(project: @project, request: @request, campaign: @campaign).call
      end
    end
  end
end
