# frozen_string_literal: true

class DiscountStackingCompatibility < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :discount
  many_to_one :compatible_discount, class: :Discount, key: :compatible_discount_id

  def validate
    super
    validates_presence [:discount_id, :compatible_discount_id]
    errors.add(:compatible_discount_id, "cannot equal discount_id") if discount_id && discount_id == compatible_discount_id
  end
end
