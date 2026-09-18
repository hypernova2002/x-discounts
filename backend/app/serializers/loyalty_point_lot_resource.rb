# frozen_string_literal: true

class LoyaltyPointLotResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :points, :points_remaining, :earned_at, :expires_at, :source

  attribute(:expired) { |lot| lot.expired? }
  attribute(:status) { |lot| lot.status }
  attribute(:order_id) { |lot| lot.order&.public_id }
  attribute(:discount_name) { |lot| lot.discount&.name }
  attribute(:reason) { |lot| lot.reason }
  attribute(:performed_by) { |lot| lot.performed_by_user&.name }
end
