# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    raw_token = bearer_token
    raise ApiError.new(:unauthorized) unless raw_token

    if raw_token.start_with?("#{ApiKey::TOKEN_PREFIX}_")
      @current_api_key = ApiKey.authenticate(raw_token)
      raise ApiError.new(:unauthorized) unless @current_api_key
    elsif raw_token.start_with?("#{Session::TOKEN_PREFIX}_")
      @current_session = Session.authenticate(raw_token)
      raise ApiError.new(:unauthorized) unless @current_session
    else
      raise ApiError.new(:unauthorized)
    end
  end

  def bearer_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    header.delete_prefix("Bearer ").strip
  end

  def current_api_key
    @current_api_key
  end

  def current_session
    @current_session
  end

  def current_user
    @current_user ||= current_api_key&.user || current_session&.user
  end

  # An API key is always scoped to the one project it was issued for. A session isn't scoped to
  # any project by itself — the frontend picks a project (once the user has one) and sends it as
  # X-Project-Id on every request; that project must actually be one the user belongs to.
  def current_project
    return @current_project if defined?(@current_project)

    @current_project =
      if current_api_key
        current_api_key.project
      elsif current_session
        project_id = request.headers["X-Project-Id"]
        project_id ? visible_project(project_id) : nil
      end
  end

  def visible_project(public_id)
    Project
      .where(public_id: public_id, account_id: current_user.account_id)
      .where(id: ProjectMembership.where(user_id: current_user.id).select(:project_id))
      .first
  end

  # For an API key this is the fixed role baked into the key. For a session it's looked up live
  # from ProjectMembership, since a session can move between projects where the user holds
  # different roles.
  def current_role
    return current_api_key.role if current_api_key
    return nil unless current_session && current_project

    ProjectMembership.first(user_id: current_user.id, project_id: current_project.id)&.role
  end

  def require_role!(*roles)
    raise ApiError.new(:forbidden) unless roles.map(&:to_s).include?(current_role)
  end

  def require_project_context!
    raise ApiError.new(:project_context_required) unless current_project
  end

  # Account-wide operations (creating a user, creating a project) aren't scoped to
  # a single project, so they're authorized by "admin on any project in the account"
  # rather than the current project's role.
  def account_admin?
    return false unless current_user

    ProjectMembership
      .where(user_id: current_user.id, role: "admin")
      .where(project_id: Project.where(account_id: current_user.account_id).select(:id))
      .any?
  end

  def require_account_admin!
    raise ApiError.new(:forbidden) unless account_admin?
  end

  # For managing a specific project's own settings/membership/keys when that project
  # may not be the one currently selected (API key scope, or session's X-Project-Id).
  def admin_of_project?(project)
    return false unless current_user

    ProjectMembership.where(user_id: current_user.id, project_id: project.id, role: "admin").any?
  end

  def require_project_admin!(project)
    raise ApiError.new(:forbidden) unless admin_of_project?(project)
  end
end
