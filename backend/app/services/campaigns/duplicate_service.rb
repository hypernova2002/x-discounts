# frozen_string_literal: true

module Campaigns
  # Cascades to duplicate every discount in the campaign (with their effects,
  # but never coupon codes — see Discounts::DuplicateService) so the result is
  # a genuinely usable copy, not an empty shell.
  class DuplicateService
    def initialize(campaign:)
      @campaign = campaign
    end

    def call
      Campaign.db.transaction do
        duplicate = Campaign.new(
          project_id: @campaign.project_id,
          name: "Copy of #{@campaign.name}",
          enabled: @campaign.enabled,
          valid_from: @campaign.valid_from,
          valid_until: @campaign.valid_until
        )
        duplicate.save

        @campaign.discounts_dataset.each do |discount|
          Discounts::DuplicateService.new(discount: discount, campaign: duplicate).call
        end

        duplicate
      end
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
