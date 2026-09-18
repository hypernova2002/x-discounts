# frozen_string_literal: true

class PointsRedemptionResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :points_redeemed, :amount_off, :refunded_points, :refunded_at, :created_at

  attribute(:refund_history) do |pr|
    pr.refund_lots_dataset.order(:created_at).all.map do |lot|
      { points: lot.points, amount_off: nil, refunded_at: lot.created_at, reason: lot.reason, performed_by: lot.performed_by_user&.name }
    end
  end
end
