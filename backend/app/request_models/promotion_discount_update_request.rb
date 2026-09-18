# frozen_string_literal: true

# Every attribute is an optional key (attribute?, no default) rather than required or
# defaulted — that's what lets the service distinguish "field omitted, leave unchanged"
# from "field explicitly sent" via `request.attributes.key?(:field)`, which is what
# proper PATCH semantics need and a single default/required value can't express.
class PromotionDiscountUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :key, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :campaign_id, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :stackable, JsonModel::Types::Bool
  attribute? :refundable, JsonModel::Types::Bool
  attribute? :enabled, JsonModel::Types::Bool
  attribute? :eligibility_condition, ConditionNode.optional
  attribute? :promotion, PromotionRequest
  attribute? :effects, JsonModel::Types::Array.of(DiscountEffectRequest).optional

  attribute? :max_redemptions, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_customer, JsonModel::Types::Integer.optional
  attribute? :max_redemptions_per_day, JsonModel::Types::Integer.optional
  attribute? :max_redemption_amount, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_day, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :max_redemption_amount_per_customer, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
end
