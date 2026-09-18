# frozen_string_literal: true

class GiftShopRedemption < Sequel::Model
  PUBLIC_ID_PREFIX = "giftr"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :customer
  many_to_one :gift_shop_item

  def validate
    super
    validates_presence %i[customer_id item_name quantity points_spent redeemed_at]
  end
end
