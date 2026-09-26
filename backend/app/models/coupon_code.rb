# frozen_string_literal: true

class CouponCode < Sequel::Model
  PUBLIC_ID_PREFIX = "cpn"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :discount
  many_to_one :customer
  many_to_one :project
  one_to_many :redemptions

  def validate
    super
    validates_presence %i[discount_id project_id code max_redemptions]
    validates_utf8_length :code, max: 255
    validates_bounded_number :max_redemptions, min: 1, max: 10_000, integer_only: true
  end

  # Redemption count, refund-aware — a refunded usage frees the slot back up, same
  # philosophy as OrderDiscount#refunded? freeing a discount-level usage-limit slot.
  def redemption_count
    redemption_ids = redemptions_dataset.select_map(:id)
    return 0 if redemption_ids.empty?

    refunded_order_discount_ids = DiscountRefund.select(:order_discount_id)
    OrderDiscount.where(redemption_id: redemption_ids).exclude(id: refunded_order_discount_ids).count
  end

  def remaining_redemptions
    max_redemptions - redemption_count
  end
end
