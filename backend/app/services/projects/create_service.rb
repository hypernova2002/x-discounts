# frozen_string_literal: true

module Projects
  class CreateService
    def initialize(account:, creator:, request:)
      @account = account
      @creator = creator
      @request = request
    end

    def call
      project = Project.new(name: @request.name, account: @account)
      membership = ProjectMembership.new(user: @creator, role: "admin")

      Project.db.transaction do
        project.save
        project.add_project_membership(membership)
      end

      project
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.from_model(project) unless project.valid?
      raise ValidationError.from_model(membership) unless membership.valid?

      raise
    end
  end
end
