# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ApiKeysController < BaseController
        MANAGE_ROLES = %w[admin].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*MANAGE_ROLES) }
        before_action :set_api_key, only: %i[show destroy]

        def index
          dataset = current_project.api_keys_dataset.order(:id)
          pagy, keys = paginate(dataset)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { api_keys: ApiKeyResource.new(keys).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: ApiKeyResource.new(@api_key).to_h
        end

        def create
          request = ApiKeyRequest.new(body)

          user = current_user.account.users_dataset.first(public_id: request.user_id)
          raise ValidationError.new(details: [{ field: "user_id", message: "is invalid" }]) unless user

          key = ApiKey.create_for(project: current_project, user: user, role: request.role, name: request.name)
          render json: ApiKeyResource.new(key, params: { include_token: true }).to_h, status: :created
        rescue Sequel::ValidationFailed => e
          raise ValidationError.from_model(e.model)
        end

        def destroy
          @api_key.revoke!
          head :no_content
        end

        private

        def set_api_key
          @api_key = current_project.api_keys_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @api_key
        end
      end
    end
  end
end
