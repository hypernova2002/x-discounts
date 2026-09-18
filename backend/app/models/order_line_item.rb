# frozen_string_literal: true

class OrderLineItem < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :order

  def validate
    super
    validates_presence %i[order_id sku quantity unit_price]
  end
end
