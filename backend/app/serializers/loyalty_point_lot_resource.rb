# frozen_string_literal: true

class LoyaltyPointLotResource < ApplicationResource
  attribute :id, &:public_id
  attributes :points, :earned_at, :expires_at, :source

  attribute(:expired) { |lot| lot.expired? }
  attribute(:reason) { |lot| lot.reason }

  attribute(:points_remaining, if: proc { included?(:points_remaining) }) do |lot|
    params[:points_remaining_by_lot]&.fetch(lot.id, nil) || lot.points_remaining
  end
  attribute(:status, if: proc { included?(:status) }) do |lot|
    params[:status_by_lot]&.fetch(lot.id, nil) || lot.status
  end
  attribute(:order_id, if: proc { included?(:order_id) }) { |lot| lot.order&.public_id }
  attribute(:discount_name, if: proc { included?(:discount_name) }) { |lot| lot.discount&.name }
  attribute(:performed_by, if: proc { included?(:performed_by) }) { |lot| lot.performed_by_user&.name }
end
