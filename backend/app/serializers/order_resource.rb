# frozen_string_literal: true

class OrderResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :total_amount, :total_discount_amount, :total_points_earned, :total_points_redeemed, :cancelled_at, :created_at

  attribute(:status) { |order| order.status }

  one :customer, resource: CustomerResource

  many :order_line_items, resource: OrderLineItemResource, key: "line_items"
  many :order_discounts, resource: OrderDiscountResource, key: "discounts"
  one :points_redemption, resource: PointsRedemptionResource
end
