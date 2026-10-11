# frozen_string_literal: true

class CampaignResource < ApplicationResource
  attribute :id, &:public_id
  attributes :name, :enabled, :archived, :valid_from, :valid_until, :created_at, :updated_at

  attribute(:active) { |campaign| campaign.active? }

  attribute(:discount_kinds, if: proc { included?(:discount_kinds) }) do |campaign|
    params[:discount_kinds_by_campaign]&.fetch(campaign.id, nil) || campaign.discounts_dataset.distinct.select_map(:kind)
  end
end
