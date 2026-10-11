# frozen_string_literal: true

class LoyaltyPointLotResource < ApplicationResource
  attribute :id, &:public_id
  attributes :points, :earned_at, :expires_at, :source

  attribute(:expired) { |lot| lot.expired? }
  attribute(:reason) { |lot| lot.reason }

  attribute(:points_remaining, if: proc { included?(:points_remaining) }) { |lot| lot.points_remaining }
  attribute(:status, if: proc { included?(:status) }) { |lot| lot.status }
  attribute(:order_id, if: proc { included?(:order_id) }) { |lot| lot.order&.public_id }
  attribute(:discount_name, if: proc { included?(:discount_name) }) { |lot| lot.discount&.name }
  attribute(:performed_by, if: proc { included?(:performed_by) }) { |lot| lot.performed_by_user&.name }
end
