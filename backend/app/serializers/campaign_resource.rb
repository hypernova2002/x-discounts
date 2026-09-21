# frozen_string_literal: true

class CampaignResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :enabled, :archived, :valid_from, :valid_until, :created_at, :updated_at

  attribute(:active) { |campaign| campaign.active? }
  attribute(:discount_kinds) { |campaign| campaign.discounts_dataset.distinct.select_map(:kind) }
end
