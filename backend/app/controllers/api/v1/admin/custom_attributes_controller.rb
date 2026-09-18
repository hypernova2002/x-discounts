# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CustomAttributesController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create destroy]
        before_action :set_custom_attribute, only: %i[destroy]

        def index
          dataset = current_project.custom_attributes_dataset.order(Sequel.desc(:id))
          dataset = dataset.where(entity: params[:entity]) if params[:entity].present?
          dataset = dataset.where(Sequel.ilike(:key, "%#{params[:q]}%")) if params[:q].present?
          pagy, custom_attributes = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { custom_attributes: CustomAttributeResource.new(custom_attributes).to_h, meta: meta_for(pagy) }
        end

        def create
          attribute = CustomAttributes::CreateService.new(project: current_project, request: CustomAttributeRequest.new(body)).call
          render json: CustomAttributeResource.new(attribute).to_h, status: :created
        end

        def destroy
          @custom_attribute.destroy
          head :no_content
        end

        private

        def set_custom_attribute
          @custom_attribute = current_project.custom_attributes_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @custom_attribute
        end
      end
    end
  end
end
