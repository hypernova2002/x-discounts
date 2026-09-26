# frozen_string_literal: true

class DiscountRefund < Sequel::Model
  PUBLIC_ID_PREFIX = "drfnd"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :order_discount
  many_to_one :performed_by_user, class: :User

  def validate
    super
    validates_presence %i[order_discount_id amount_off refunded_at]
    validates_bounded_number :amount_off, min: 0, max: 100_000_000
    validates_utf8_length :reason, max: 10_000
  end
end
