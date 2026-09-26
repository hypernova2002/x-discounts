# frozen_string_literal: true

class OrderDiscount < Sequel::Model
  PUBLIC_ID_PREFIX = "ordisc"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :order
  many_to_one :discount
  many_to_one :redemption
  many_to_one :loyalty_point_lot
  one_to_many :discount_refunds

  add_association_dependencies discount_refunds: :destroy

  def validate
    super
    validates_presence %i[order_id kind discount_key discount_name effect_type]
    validates_utf8_length :kind, max: 255
    validates_utf8_length :discount_key, max: 255
    validates_utf8_length :discount_name, max: 1000
    validates_utf8_length :effect_type, max: 255
    validates_utf8_length :sku, max: 255
    validates_bounded_number :amount_off, min: 0, max: 100_000_000
  end

  # Loyalty points are attributed at the lot level, not per effect-row — a discount
  # with several effects can produce several sibling rows sharing one lot, and trying
  # to split a post-multiplier total across them is exactly what caused the original
  # over/under-refund bug. So every sibling row just shows the lot's own totals.
  def total_points_earned
    loyalty_point_lot&.points
  end

  def total_points_refunded
    return nil unless loyalty_point_lot

    loyalty_point_lot.ledger_entries_dataset.where(kind: "clawback").sum(Sequel.lit("-delta")).to_i
  end

  def remaining_refundable_points
    return nil unless loyalty_point_lot

    loyalty_point_lot.points - (total_points_refunded || 0)
  end

  def refunded_amount_off
    return nil if amount_off.nil?

    discount_refunds_dataset.sum(:amount_off) || 0
  end

  def remaining_refundable_amount_off
    return nil if amount_off.nil?

    amount_off - refunded_amount_off
  end

  # Row-scoped (unlike the lot-wide totals above) — this is "did refunding THIS row
  # ever happen," used by UsageLimitChecker to decide whether it still counts toward
  # usage limits. Deliberately independent of the shared-lot budget check.
  def refunded?
    if kind == "loyalty"
      return false unless loyalty_point_lot

      loyalty_point_lot.ledger_entries_dataset.where(kind: "clawback", order_discount_id: id).any?
    else
      discount_refunds_dataset.any?
    end
  end
end
