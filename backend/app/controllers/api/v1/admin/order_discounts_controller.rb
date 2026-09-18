# frozen_string_literal: true

module Api
  module V1
    module Admin
      class OrderDiscountsController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }
        before_action :set_order_discount

        def refund
          request = RefundRequest.new(body)
          result = Refunds::CreateService.new(
            order_discount: @order_discount, amount_off: request.amount_off, points: request.points,
            reason: request.reason, performed_by: current_user
          ).call
          render json: result, status: :created
        end

        private

        def set_order_discount
          @order_discount = OrderDiscount
                             .where(order_id: current_project.orders_dataset.select(:id))
                             .first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @order_discount
        end
      end
    end
  end
end
