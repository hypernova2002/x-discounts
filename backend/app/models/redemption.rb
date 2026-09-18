# frozen_string_literal: true

class Redemption < Sequel::Model
  PUBLIC_ID_PREFIX = "redm"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :discount
  many_to_one :customer
  many_to_one :coupon_code

  def validate
    super
    validates_presence [:discount_id, :customer_id, :redeemed_at, :coupon_code_id]
  end
end
