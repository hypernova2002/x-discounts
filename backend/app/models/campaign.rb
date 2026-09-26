# frozen_string_literal: true

class Campaign < Sequel::Model
  PUBLIC_ID_PREFIX = "camp"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project
  one_to_many :discounts

  def validate
    super
    validates_presence %i[project_id name]
    validates_utf8_length :name, max: 1000
    validates_boolean :enabled
    validates_boolean :archived
  end

  def active?(now = Time.now.utc)
    enabled && !archived && (valid_from.nil? || valid_from <= now) && (valid_until.nil? || now <= valid_until)
  end

  # A single-entity aggregate (computed on demand for one campaign, same shape as
  # CustomersController's customer_stats) — not meant for list views. Refund-aware
  # via OrderDiscount#refunded?, same reasoning as Discount#redemption_count: loyalty
  # rows are refunded through a ledger clawback rather than a DiscountRefund record,
  # so per-row #refunded? is the one place that distinction needs to be right.
  def discount_summary
    order_discounts = OrderDiscount.where(discount_id: discounts_dataset.select(:id)).all
    active_discounts = order_discounts.reject(&:refunded?)
    refunded_amount = order_discounts.empty? ? 0 : (DiscountRefund.where(order_discount_id: order_discounts.map(&:id)).sum(:amount_off) || 0)
    discounted_amount = order_discounts.sum { |od| od.amount_off || 0 } - refunded_amount

    { count: discounts_dataset.count, redemption_count: active_discounts.size, discounted_amount: discounted_amount }
  end
end
