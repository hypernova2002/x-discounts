# frozen_string_literal: true

module Orders
  # Cancelling never touches money by itself (this app has no payment gateway) — it
  # just stamps cancelled_at. The optional refund is the part with real side effects:
  # it auto-issues a full refund (via Refunds::CreateService) for every line whose
  # discount has refundable: true, and never for one that doesn't — that flag is a
  # hard rule here, unlike the manual per-line refund action which can override it.
  class CancelService
    def initialize(order:, refund: false, reason: nil, performed_by: nil)
      @order = order
      @refund = refund
      @reason = reason
      @performed_by = performed_by
    end

    def call
      Order.db.transaction do
        order = @order.lock!
        raise ValidationError.new(details: [{ field: "base", message: "order is already cancelled" }]) if order.cancelled?

        order.update(cancelled_at: Time.now.utc)
        auto_refund(order) if @refund
      end

      @order.refresh
    end

    private

    def auto_refund(order)
      order.order_discounts_dataset.eager(:discount).all.each do |order_discount|
        next unless order_discount.discount&.refundable

        if order_discount.kind == "loyalty"
          remaining = order_discount.remaining_refundable_points.to_i
          next if remaining <= 0

          refund_line(order_discount: order_discount, points: remaining)
        else
          remaining = order_discount.remaining_refundable_amount_off
          next if remaining.nil? || remaining <= 0

          refund_line(order_discount: order_discount, amount_off: remaining)
        end
      end

      points_redemption = order.points_redemption
      return unless points_redemption && points_redemption.remaining_refundable_points.positive?

      refund_line(points_redemption: points_redemption, points: points_redemption.remaining_refundable_points)
    end

    # Best-effort: a line that can't actually be refunded (e.g. a pre-ledger legacy
    # order whose points went into one aggregate lot with no per-order trace) doesn't
    # block cancelling the order or refunding every other eligible line.
    def refund_line(**kwargs)
      Refunds::CreateService.new(reason: @reason || "order cancelled", performed_by: @performed_by, **kwargs).call
    rescue ValidationError
      nil
    end
  end
end
