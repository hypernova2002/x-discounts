# frozen_string_literal: true

module Api
  module V1
    class DiscountRedemptionsController < ApplicationController
      # This is the stable, external-integration-facing API (unlike the admin
      # dashboard API, which lets the frontend opt into includes= per view) — it
      # keeps returning every field it always has, by always requesting every
      # includes= gate the whole OrderResource tree defines.
      FULL_RESOURCE_PARAMS = {
        includes: %w[customer membership_tier membership_scheme order_line_items order_discounts points_redemption
                      points_earned refunded_points refunded_amount_off discount_id refundable refund_history]
      }.freeze

      before_action :require_project_context!

      def create
        request = DiscountValidationRequest.new(body)
        result = Discounts::RedeemService.new(
          project: current_project,
          cart: request.cart,
          line_items: request.line_items,
          customer: request.customer,
          coupon_codes: request.coupon_codes,
          redeem_points: request.redeem_points
        ).call
        render json: OrderResource.new(result[:order], params: FULL_RESOURCE_PARAMS).to_h.merge(coupons: result[:coupons], points_redemption: result[:points_redemption]), status: :created
      end
    end
  end
end
