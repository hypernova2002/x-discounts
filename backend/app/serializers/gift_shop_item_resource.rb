# frozen_string_literal: true

class GiftShopItemResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :description, :points_cost, :stock, :enabled, :created_at, :updated_at

  attribute(:in_stock) { |item| item.in_stock? }
  attribute(:photo_url) { |item| item.photo? ? "/api/v1/admin/gift_shop_items/#{item.public_id}/photo" : nil }
end
