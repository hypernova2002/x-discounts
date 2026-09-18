# frozen_string_literal: true

module Api
  module V1
    module Admin
      class DiscountsController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create update destroy]
        before_action :set_discount, only: %i[show update destroy]

        def index
          dataset = current_project.discounts_dataset.order(Sequel.desc(:id))
          dataset = dataset.where(kind: params[:kind]) if params[:kind].present?
          if params[:campaign_id].present?
            campaign = current_project.campaigns_dataset.first(public_id: params[:campaign_id])
            raise ApiError.new(:not_found) unless campaign

            dataset = dataset.where(campaign_id: campaign.id)
          end
          if params[:q].present?
            matching_by_code = CouponCode.where(project_id: current_project.id).where(Sequel.ilike(:code, "%#{params[:q]}%")).select(:discount_id)
            dataset = dataset.where(Sequel.ilike(:name, "%#{params[:q]}%") | { id: matching_by_code })
          end
          pagy, discounts = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { discounts: DiscountResource.new(discounts).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: DiscountResource.new(@discount).to_h
        end

        def create
          request = DiscountRequest.build(body)
          discount = Discounts::CreateService.new(
            project: current_project,
            request: request,
            campaign: find_campaign!(request.campaign_id)
          ).call
          render json: DiscountResource.new(discount).to_h, status: :created
        end

        def update
          request = DiscountUpdateRequest.build(body, kind: @discount.kind)
          campaign = find_campaign!(request.campaign_id) if request.attributes.key?(:campaign_id)
          discount = Discounts::UpdateService.new(discount: @discount, request: request, campaign: campaign).call
          render json: DiscountResource.new(discount).to_h
        end

        def destroy
          @discount.destroy
          head :no_content
        rescue Sequel::ForeignKeyConstraintViolation
          raise ValidationError.new(details: [{ field: "base", message: "cannot delete a discount with redeemed coupon codes" }])
        end

        private

        def set_discount
          @discount = current_project.discounts_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @discount
        end

        def find_campaign!(campaign_id)
          campaign = current_project.campaigns_dataset.first(public_id: campaign_id)
          raise ValidationError.new(details: [{ field: "campaign_id", message: "does not refer to an existing campaign" }]) unless campaign

          campaign
        end
      end
    end
  end
end
