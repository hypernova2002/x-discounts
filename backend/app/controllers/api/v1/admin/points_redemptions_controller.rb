# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PointsRedemptionsController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }
        before_action :set_points_redemption

        def refund
          request = RefundRequest.new(body)
          result = Refunds::CreateService.new(
            points_redemption: @points_redemption, points: request.points,
            reason: request.reason, performed_by: current_user
          ).call
          render json: result, status: :created
        end

        private

        def set_points_redemption
          @points_redemption = PointsRedemption
                                .where(order_id: current_project.orders_dataset.select(:id))
                                .first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @points_redemption
        end
      end
    end
  end
end
