# frozen_string_literal: true

module Api
  module V1
    module Admin
      class MembershipTiersController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }
        before_action :set_scheme
        before_action :set_tier, only: %i[update]

        def create
          tier = MembershipTiers::CreateService.new(scheme: @scheme, request: MembershipTierRequest.new(body)).call
          render json: MembershipTierResource.new(tier).to_h, status: :created
        end

        def update
          tier = MembershipTiers::UpdateService.new(tier: @tier, request: MembershipTierUpdateRequest.new(body)).call
          render json: MembershipTierResource.new(tier).to_h
        end

        private

        def set_scheme
          @scheme = current_project.membership_schemes_dataset.first(public_id: params[:membership_scheme_id])
          raise ApiError.new(:not_found) unless @scheme
        end

        def set_tier
          @tier = @scheme.membership_tiers_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @tier
        end
      end
    end
  end
end
