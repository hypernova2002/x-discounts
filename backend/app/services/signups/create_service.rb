# frozen_string_literal: true

module Signups
  class CreateService
    ERROR_PREFIXES = {
      Account => "account",
      Project => "project",
      ProjectMembership => "membership"
    }.freeze

    def initialize(request:)
      @request = request
    end

    def call
      account = Account.new(name: @request.account_name)
      user = nil
      session = nil

      Account.db.transaction do
        account.save

        user = account.add_user(
          name: @request.name,
          email: @request.email,
          password: @request.password,
          password_confirmation: @request.password_confirmation
        )

        project = account.add_project(name: "Default")
        project.add_project_membership(user: user, role: "admin")

        session = Session.create_for(user: user)
      end

      { user: user, session: session }
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model, prefix: ERROR_PREFIXES[e.model.class])
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.from_model(user) if user && !user.valid?

      raise
    end
  end
end
