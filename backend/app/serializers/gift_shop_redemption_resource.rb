# frozen_string_literal: true

class GiftShopRedemptionResource < ApplicationResource
  attribute :id, &:public_id
  attributes :item_name, :quantity, :points_spent, :redeemed_at

  attribute(:item_id, if: proc { included?(:item_id) }) { |redemption| redemption.gift_shop_item&.public_id }
  attribute(:customer_id, if: proc { included?(:customer_id) }) { |redemption| redemption.customer.public_id }
end
