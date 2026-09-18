# frozen_string_literal: true

# See PromotionDiscountUpdateRequest — every attribute is an optional key (no default)
# so the service can tell "omitted" from "explicitly sent" via `attributes.key?(:field)`.
class LoyaltyDiscountUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :key, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :campaign_id, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :stackable, JsonModel::Types::Bool
  attribute? :refundable, JsonModel::Types::Bool
  attribute? :enabled, JsonModel::Types::Bool
  attribute? :eligibility_condition, ConditionNode.optional
  attribute? :loyalty, LoyaltyRequest
  attribute? :effects, JsonModel::Types::Array.of(DiscountEffectRequest).optional

  attribute? :max_redemptions, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_customer, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_day, JsonModel::Types::Integer.optional
  attribute? :max_redemption_amount, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_day, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_customer, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
end
