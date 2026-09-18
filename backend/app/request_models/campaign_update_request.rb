# frozen_string_literal: true

# Every attribute is an optional key (no default) so the service can distinguish
# "omitted, leave unchanged" from "explicitly sent" via `attributes.key?(:field)` —
# same PATCH-semantics pattern as PromotionDiscountUpdateRequest.
class CampaignUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :enabled, JsonModel::Types::Bool
  attribute? :archived, JsonModel::Types::Bool
  attribute? :valid_from, JsonModel::Types::String.optional
  attribute? :valid_until, JsonModel::Types::String.optional
end
