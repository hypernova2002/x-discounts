# frozen_string_literal: true

module Api
  module V1
    class DiscountRedemptionsController < ApplicationController
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
        render json: OrderResource.new(result[:order]).to_h.merge(coupons: result[:coupons], points_redemption: result[:points_redemption]), status: :created
      end
    end
  end
end
