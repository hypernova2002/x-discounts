# frozen_string_literal: true

module Campaigns
  class CreateService
    def initialize(project:, request:)
      @project = project
      @request = request
    end

    def call
      campaign = Campaign.new(
        project: @project,
        name: @request.name,
        enabled: @request.enabled,
        valid_from: @request.valid_from,
        valid_until: @request.valid_until
      )
      campaign.save
      campaign
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
