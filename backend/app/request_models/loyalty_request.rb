# frozen_string_literal: true

class LoyaltyRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :active_from, JsonModel::Types::String
  attribute? :active_until, JsonModel::Types::String.optional
  # Null/omitted means points earned from this discount never expire.
  attribute? :points_expire_after_days, JsonModel::Types::Integer.constrained(gt: 0).optional
end
