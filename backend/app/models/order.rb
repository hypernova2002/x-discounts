# frozen_string_literal: true

class Order < Sequel::Model
  PUBLIC_ID_PREFIX = "ord"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :project
  many_to_one :customer
  one_to_many :order_line_items
  one_to_many :order_discounts
  one_to_one :points_redemption

  add_association_dependencies order_line_items: :destroy, order_discounts: :destroy, points_redemption: :destroy

  def validate
    super
    validates_presence %i[project_id customer_id]
    validates_bounded_number :total_amount, min: 0, max: 100_000_000
    validates_bounded_number :total_discount_amount, min: 0, max: 100_000_000
  end

  def cancelled?
    cancelled_at.present?
  end

  def total_points_earned
    LoyaltyPointLot.where(order_id: id, source: "order").sum(:points) || 0
  end

  def total_points_redeemed
    points_redemption&.points_redeemed || 0
  end

  # Computed, not stored — see Refunds::CreateService and the loyalty points ledger.
  # free_items-only lines have no measurable amount, so they're excluded from the
  # fully-refunded check rather than forced into an undefined "partial" state.
  def status
    refunded_state = any_refund? ? (fully_refunded? ? "refunded" : "partially_refunded") : nil
    refunded_state || (cancelled? ? "cancelled" : "active")
  end

  def any_refund?
    order_discounts.any?(&:refunded?) || (points_redemption && points_redemption.refunded_points.positive?)
  end

  def fully_refunded?
    order_discounts.all? do |od|
      next true if od.amount_off.nil? && od.kind != "loyalty" # free_items-only: not measurable, doesn't block "fully"
      next (od.remaining_refundable_amount_off || 0) <= 0 if od.amount_off
      next true if od.total_points_earned.nil? # multiplier-only loyalty row, nothing of its own to refund

      (od.remaining_refundable_points || 0) <= 0
    end && (points_redemption.nil? || points_redemption.remaining_refundable_points <= 0)
  end
end
