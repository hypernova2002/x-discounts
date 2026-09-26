# frozen_string_literal: true

class GiftShopRedemption < Sequel::Model
  PUBLIC_ID_PREFIX = "giftr"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :customer
  many_to_one :gift_shop_item

  def validate
    super
    validates_presence %i[customer_id item_name quantity points_spent redeemed_at]
    validates_utf8_length :item_name, max: 1000
    validates_bounded_number :quantity, min: 1, max: 100_000, integer_only: true
    validates_bounded_number :points_spent, min: 0, max: 10_000_000, integer_only: true
  end
end
