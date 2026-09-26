# frozen_string_literal: true

class LoyaltyPointLedgerEntry < Sequel::Model
  PUBLIC_ID_PREFIX = "lple"
  KINDS = %w[spend clawback].freeze

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :loyalty_point_lot
  many_to_one :points_redemption
  many_to_one :gift_shop_redemption
  many_to_one :order_discount
  many_to_one :performed_by_user, class: :User

  def validate
    super
    validates_presence %i[loyalty_point_lot_id delta kind]
    validates_includes KINDS, :kind, allow_missing: true
    validates_bounded_number :delta, min: -10_000_000, max: -1, integer_only: true
    validates_utf8_length :reason, max: 10_000

    case kind
    when "spend"
      errors.add(:base, "spend must reference a points_redemption or gift_shop_redemption") if points_redemption_id.nil? && gift_shop_redemption_id.nil?
    when "clawback"
      errors.add(:order_discount_id, "is required for a clawback") if order_discount_id.nil?
    end
  end
end
