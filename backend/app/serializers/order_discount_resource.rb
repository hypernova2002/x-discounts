# frozen_string_literal: true

class OrderDiscountResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :kind, :discount_key, :discount_name, :effect_type, :amount_off, :sku

  attribute(:points_earned) { |od| od.total_points_earned }
  attribute(:refunded_points) { |od| od.total_points_refunded }
  attribute(:refunded_amount_off) { |od| od.refunded_amount_off }
  attribute(:discount_id) { |od| od.discount&.public_id }
  attribute(:refundable) { |od| od.discount&.refundable }
  attribute(:free_items) { |od| od.free_items&.to_a }

  # Full history (not just the rollup above) — a line can be partially refunded more
  # than once, each with its own reason/actor.
  attribute(:refund_history) do |od|
    if od.kind == "loyalty"
      next [] unless od.loyalty_point_lot

      od.loyalty_point_lot.ledger_entries_dataset.where(kind: "clawback", order_discount_id: od.id).order(:created_at).all.map do |e|
        { points: -e.delta, amount_off: nil, refunded_at: e.created_at, reason: e.reason, performed_by: e.performed_by_user&.name }
      end
    else
      od.discount_refunds_dataset.order(:refunded_at).all.map do |r|
        { points: nil, amount_off: r.amount_off, refunded_at: r.refunded_at, reason: r.reason, performed_by: r.performed_by_user&.name }
      end
    end
  end
end
