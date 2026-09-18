# frozen_string_literal: true

module MembershipSchemes
  class CreateService
    def initialize(project:, request:)
      @project = project
      @request = request
    end

    def call
      scheme = MembershipScheme.new(project: @project, name: @request.name)
      scheme.save
      scheme
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
