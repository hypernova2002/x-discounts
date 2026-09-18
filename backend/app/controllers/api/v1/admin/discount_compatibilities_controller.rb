# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Nested under discounts (/admin/discounts/:discount_id/compatible_discounts) —
      # manages explicit exceptions letting two otherwise-exclusive (stackable: false)
      # discounts combine anyway. See Discounts::StackingResolver.
      class DiscountCompatibilitiesController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }
        before_action :set_discount

        def create
          request = DiscountCompatibilityRequest.new(body)
          compatible = find_discount!(request.compatible_discount_id)
          DiscountStackingCompatibilities::CreateService.new(discount: @discount, compatible_discount: compatible).call
          render json: DiscountResource.new(@discount.refresh).to_h, status: :created
        rescue Sequel::ValidationFailed => e
          raise ValidationError.from_model(e.model)
        end

        def destroy
          compatible = find_discount!(params[:id])
          DiscountStackingCompatibilities::DestroyService.new(discount: @discount, compatible_discount: compatible).call
          head :no_content
        end

        private

        def set_discount
          @discount = current_project.discounts_dataset.first(public_id: params[:discount_id])
          raise ApiError.new(:not_found) unless @discount
        end

        def find_discount!(public_id)
          discount = current_project.discounts_dataset.first(public_id: public_id)
          raise ValidationError.new(details: [{ field: "compatible_discount_id", message: "does not refer to an existing discount" }]) unless discount

          discount
        end
      end
    end
  end
end
