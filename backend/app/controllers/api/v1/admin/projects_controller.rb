# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProjectsController < BaseController
        before_action -> { require_account_admin! }, only: %i[create]
        before_action :set_project, only: %i[show update destroy]
        before_action -> { require_project_admin!(@project) }, only: %i[update destroy]

        def index
          dataset = visible_projects_dataset.order(:id)
          pagy, projects = paginate(dataset)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { projects: ProjectResource.new(projects).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: ProjectResource.new(@project).to_h
        end

        def create
          request = ProjectRequest.new(body)
          project = Projects::CreateService.new(account: current_user.account, creator: current_user, request: request).call
          render json: ProjectResource.new(project).to_h, status: :created
        end

        def update
          @project.set(name: body.key?(:name) ? body[:name] : @project.name)
          raise ValidationError.from_model(@project) unless @project.valid?

          @project.save
          render json: ProjectResource.new(@project).to_h
        end

        def destroy
          @project.destroy
          head :no_content
        end

        private

        def visible_projects_dataset
          Project
            .where(account_id: current_user.account_id)
            .where(id: ProjectMembership.where(user_id: current_user.id).select(:project_id))
        end

        def set_project
          @project = visible_projects_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @project
        end
      end
    end
  end
end
