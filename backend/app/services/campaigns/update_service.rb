# frozen_string_literal: true

module Campaigns
  class UpdateService
    def initialize(campaign:, request:)
      @campaign = campaign
      @request = request
    end

    def call
      @campaign.set(campaign_attrs)
      @campaign.save
      @campaign
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def campaign_attrs
      attrs = {}
      attrs[:name] = @request.name if @request.attributes.key?(:name)
      attrs[:enabled] = @request.enabled if @request.attributes.key?(:enabled)
      attrs[:archived] = @request.archived if @request.attributes.key?(:archived)
      attrs[:valid_from] = @request.valid_from if @request.attributes.key?(:valid_from)
      attrs[:valid_until] = @request.valid_until if @request.attributes.key?(:valid_until)
      attrs
    end
  end
end
