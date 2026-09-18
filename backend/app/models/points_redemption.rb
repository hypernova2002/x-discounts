# frozen_string_literal: true

class PointsRedemption < Sequel::Model
  PUBLIC_ID_PREFIX = "ptsr"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :order
  many_to_one :customer
  # Refunding a redemption spins up a fresh lot (source: redemption_refund) rather
  # than crediting back into whatever original lots the FIFO spend drew from — those
  # may have since expired, and a fresh lot lets the refund control its own expiry.
  one_to_many :refund_lots, class: :LoyaltyPointLot, key: :refund_of_points_redemption_id

  def validate
    super
    validates_presence %i[order_id customer_id points_redeemed amount_off]
  end

  def refunded_points
    refund_lots_dataset.sum(:points) || 0
  end

  def refunded_at
    refund_lots_dataset.max(:created_at)
  end

  def remaining_refundable_points
    points_redeemed - refunded_points
  end
end
