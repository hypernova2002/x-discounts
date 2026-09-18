# frozen_string_literal: true

module Api
  module V1
    class DiscountValidationsController < ApplicationController
      before_action :require_project_context!

      def create
        request = DiscountValidationRequest.new(body)
        result = Discounts::ValidationService.new(
          project: current_project,
          cart: request.cart,
          line_items: request.line_items,
          customer: request.customer,
          coupon_codes: request.coupon_codes,
          as_of: request.as_of,
          redeem_points: request.redeem_points
        ).call
        render json: result
      end
    end
  end
end
