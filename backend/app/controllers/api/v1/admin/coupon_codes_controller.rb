# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CouponCodesController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create destroy]
        before_action :set_discount

        def index
          dataset = @discount.coupon_codes_dataset.order(Sequel.desc(:id))
          pagy, codes = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { coupon_codes: CouponCodeResource.new(codes).to_h, meta: meta_for(pagy) }
        end

        def create
          request = CouponCodeGenerateRequest.new(body)
          codes = CouponCodes::GenerateService.new(discount: @discount, project: current_project, request: request).call
          render json: CouponCodeResource.new(codes).to_h, status: :created
        end

        def destroy
          code = @discount.coupon_codes_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless code

          code.destroy
          head :no_content
        rescue Sequel::ForeignKeyConstraintViolation
          raise ValidationError.new(details: [{ field: "base", message: "cannot delete a code that has already been redeemed" }])
        end

        private

        def set_discount
          @discount = current_project.discounts_dataset.first(public_id: params[:discount_id], kind: "coupon")
          raise ApiError.new(:not_found) unless @discount
        end
      end
    end
  end
end
