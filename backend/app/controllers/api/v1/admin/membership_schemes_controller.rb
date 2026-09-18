# frozen_string_literal: true

module Api
  module V1
    module Admin
      class MembershipSchemesController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create update evaluate]
        before_action :set_scheme, only: %i[show update]

        def index
          dataset = current_project.membership_schemes_dataset.order(Sequel.desc(:id))
          pagy, schemes = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { membership_schemes: MembershipSchemeResource.new(schemes).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: MembershipSchemeResource.new(@scheme).to_h
        end

        def create
          scheme = MembershipSchemes::CreateService.new(project: current_project, request: MembershipSchemeRequest.new(body)).call
          render json: MembershipSchemeResource.new(scheme).to_h, status: :created
        end

        def update
          scheme = MembershipSchemes::UpdateService.new(scheme: @scheme, request: MembershipSchemeUpdateRequest.new(body)).call
          render json: MembershipSchemeResource.new(scheme).to_h
        end

        # Runs the same re-evaluation MembershipTierSweepJob would, synchronously and
        # scoped to the current project — since nothing schedules that job yet, this
        # is the only way to actually see the effect of a requirements_condition
        # change (or a customer going quiet) without waiting for their next order.
        def evaluate
          count = 0
          current_project.customers_dataset.each do |customer|
            Memberships::EvaluateCustomerService.new(customer: customer).call
            count += 1
          end
          render json: { evaluated: count }
        end

        private

        def set_scheme
          @scheme = current_project.membership_schemes_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @scheme
        end
      end
    end
  end
end
