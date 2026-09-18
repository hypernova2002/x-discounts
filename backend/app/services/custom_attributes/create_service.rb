# frozen_string_literal: true

module CustomAttributes
  class CreateService
    def initialize(project:, request:)
      @project = project
      @request = request
    end

    def call
      attribute = CustomAttribute.new(
        project: @project,
        entity: @request.entity,
        key: @request.key,
        data_type: @request.data_type
      )
      attribute.save
      attribute
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    rescue Sequel::UniqueConstraintViolation
      raise ValidationError.from_model(attribute) unless attribute.valid?

      raise
    end
  end
end
