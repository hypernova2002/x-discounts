# frozen_string_literal: true

class CouponDiscountRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :key, JsonModel::Types::String.constrained(min_size: 1).optional
  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute :campaign_id, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :stackable, JsonModel::Types::Bool.default(false)
  attribute? :refundable, JsonModel::Types::Bool.default(true)
  attribute? :enabled, JsonModel::Types::Bool.default(true)
  attribute? :eligibility_condition, ConditionNode.optional
  attribute :coupon, CouponRequest
  attribute? :effects, JsonModel::Types::Array.of(DiscountEffectRequest).optional

  attribute? :max_redemptions, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_customer, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_day, JsonModel::Types::Integer.optional
  attribute? :max_redemption_amount, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_day, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_customer, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
end
