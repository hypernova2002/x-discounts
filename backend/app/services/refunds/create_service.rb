# frozen_string_literal: true

module Refunds
  # Refunds are always partial-capable: pass an explicit amount/points to refund only
  # that much, or omit it to refund whatever's left. Either way the amount is capped at
  # what's actually still outstanding.
  #
  # Two distinct kinds of line can be refunded:
  # - An OrderDiscount: "loyalty" kind claws back points by inserting a ledger entry
  #   against the lot it created (order_discounts.loyalty_point_lot_id) — the lot is
  #   the shared budget, so this is safe even when several sibling rows (one discount,
  #   several effects) point at the same lot. Any other kind has no customer balance
  #   to touch, so refunding it is pure bookkeeping (a DiscountRefund row), which also
  #   frees up the discount's usage-limit slot via OrderDiscount#refunded?.
  # - A PointsRedemption: returns points to the customer as a new, non-expiring lot
  #   (source: redemption_refund) — not by reversing whatever the customer originally
  #   spent them from, since those source lots may have moved on by refund time.
  #
  # Returns a plain {amount_off:, points:, refunded_at:} hash — callers don't need to
  # know which underlying row type (DiscountRefund / LoyaltyPointLedgerEntry / a fresh
  # LoyaltyPointLot) actually recorded it.
  class CreateService
    def initialize(order_discount: nil, points_redemption: nil, amount_off: nil, points: nil, reason: nil, performed_by: nil)
      if order_discount.nil? == points_redemption.nil?
        raise ArgumentError, "exactly one of order_discount or points_redemption is required"
      end

      @order_discount = order_discount
      @points_redemption = points_redemption
      @requested_amount_off = amount_off
      @requested_points = points
      @reason = reason
      @performed_by = performed_by
    end

    def call
      @order_discount ? refund_order_discount : refund_points_redemption
    end

    private

    def refund_order_discount
      order_discount = @order_discount.lock!
      order_discount.kind == "loyalty" ? refund_loyalty_line(order_discount) : refund_plain_discount_line(order_discount)
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    def refund_loyalty_line(order_discount)
      lot = order_discount.loyalty_point_lot
      raise ValidationError.new(details: [{ field: "base", message: "no linked points lot found for this discount line" }]) unless lot

      already_clawed_back = lot.ledger_entries_dataset.where(kind: "clawback").sum(Sequel.lit("-delta")) || 0
      remaining = lot.points - already_clawed_back
      points = [@requested_points || remaining, remaining].min
      raise ValidationError.new(details: [{ field: "points", message: "nothing left to refund" }]) if points <= 0

      order = order_discount.order
      now = Time.now.utc
      LoyaltyPointLedgerEntry.db.transaction do
        # Customer locked before the lot, matching the fixed customer-then-discount
        # lock order everywhere else points are earned/spent.
        order.customer.lock!
        LoyaltyPointLedgerEntry.create(
          loyalty_point_lot: lot, delta: -points, kind: "clawback", order_discount: order_discount, created_at: now,
          reason: @reason, performed_by_user: @performed_by
        )
      end

      { amount_off: nil, points: points, refunded_at: now }
    end

    def refund_plain_discount_line(order_discount)
      remaining = order_discount.remaining_refundable_amount_off || 0
      amount = [@requested_amount_off || remaining, remaining].min
      raise ValidationError.new(details: [{ field: "amount_off", message: "nothing left to refund" }]) if amount <= 0

      now = Time.now.utc
      DiscountRefund.create(order_discount: order_discount, amount_off: amount, refunded_at: now, reason: @reason, performed_by_user: @performed_by)
      { amount_off: amount, points: nil, refunded_at: now }
    end

    def refund_points_redemption
      result = nil
      now = Time.now.utc

      LoyaltyPointLot.db.transaction do
        customer = @points_redemption.customer.lock!
        points_redemption = @points_redemption.lock!

        remaining = points_redemption.remaining_refundable_points
        points = [@requested_points || remaining, remaining].min
        raise ValidationError.new(details: [{ field: "points", message: "nothing left to refund" }]) if points <= 0

        customer.add_loyalty_point_lot(
          order: points_redemption.order,
          points: points,
          earned_at: now,
          expires_at: nil,
          source: "redemption_refund",
          refund_of_points_redemption: points_redemption,
          reason: @reason,
          performed_by_user: @performed_by
        )

        result = { amount_off: nil, points: points, refunded_at: now }
      end

      result
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
