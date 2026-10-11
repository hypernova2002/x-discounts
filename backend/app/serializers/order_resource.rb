# frozen_string_literal: true

class OrderResource < ApplicationResource
  attribute :id, &:public_id
  attributes :total_amount, :total_discount_amount, :total_points_earned, :total_points_redeemed, :cancelled_at, :created_at

  # Always-on: Order#status reads the order_discounts association regardless
  # of whether the nested `discounts` array below is itself requested, so
  # gating this wouldn't save a query — only gate the serialized array.
  attribute(:status) { |order| order.status }

  one :customer, resource: CustomerResource, if: proc { included?(:customer) }

  many :order_line_items, resource: OrderLineItemResource, key: "line_items", if: proc { included?(:order_line_items) }
  many :order_discounts, resource: OrderDiscountResource, key: "discounts", if: proc { included?(:order_discounts) }
  one :points_redemption, resource: PointsRedemptionResource, if: proc { included?(:points_redemption) }
end
