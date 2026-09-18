# frozen_string_literal: true

module MembershipSchemes
  class UpdateService
    def initialize(scheme:, request:)
      @scheme = scheme
      @request = request
    end

    def call
      @scheme.name = @request.name if @request.attributes.key?(:name)
      @scheme.save
      @scheme
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
