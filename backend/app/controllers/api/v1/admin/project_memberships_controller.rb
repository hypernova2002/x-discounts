# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProjectMembershipsController < BaseController
        MANAGE_ROLES = %w[admin].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*MANAGE_ROLES) }, only: %i[create update destroy]
        before_action :set_membership, only: %i[show update destroy]

        def index
          dataset = current_project.project_memberships_dataset.order(:id)
          pagy, memberships = paginate(dataset)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { project_memberships: ProjectMembershipResource.new(memberships).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: ProjectMembershipResource.new(@membership).to_h
        end

        def create
          request = ProjectMembershipRequest.new(body)

          user = current_user.account.users_dataset.first(public_id: request.user_id)
          raise ValidationError.new(details: [{ field: "user_id", message: "is invalid" }]) unless user

          membership = ProjectMembership.new(
            project_id: current_project.id,
            user_id: user.id,
            role: request.role
          )
          raise ValidationError.from_model(membership) unless membership.valid?

          membership.save
          render json: ProjectMembershipResource.new(membership).to_h, status: :created
        end

        def update
          if @membership.role == "admin" && body[:role] != "admin" && last_admin?(@membership)
            raise ValidationError.new(details: [{ field: "role", message: "cannot demote the last admin of a project" }])
          end

          @membership.set(role: body.key?(:role) ? body[:role] : @membership.role)
          raise ValidationError.from_model(@membership) unless @membership.valid?

          @membership.save
          render json: ProjectMembershipResource.new(@membership).to_h
        end

        def destroy
          if @membership.role == "admin" && last_admin?(@membership)
            raise ValidationError.new(details: [{ field: "role", message: "cannot remove the last admin of a project" }])
          end

          @membership.destroy
          head :no_content
        end

        private

        def last_admin?(membership)
          current_project.project_memberships_dataset.where(role: "admin").exclude(id: membership.id).empty?
        end

        def set_membership
          @membership = current_project.project_memberships_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @membership
        end
      end
    end
  end
end
