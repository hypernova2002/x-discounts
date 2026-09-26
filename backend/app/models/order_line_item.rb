# frozen_string_literal: true

class OrderLineItem < Sequel::Model
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :order

  def validate
    super
    validates_presence %i[order_id sku quantity unit_price]
    validates_utf8_length :sku, max: 255
    validates_bounded_number :quantity, min: 1, max: 100_000, integer_only: true
    validates_bounded_number :unit_price, min: 0, max: 100_000_000
  end
end
