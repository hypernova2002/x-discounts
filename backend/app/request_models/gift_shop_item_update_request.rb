# frozen_string_literal: true

class GiftShopItemUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :description, JsonModel::Types::String.optional
  attribute? :points_cost, JsonModel::Types::Integer.constrained(gt: 0)
  attribute? :stock, JsonModel::Types::Integer.constrained(gteq: 0).optional
  attribute? :enabled, JsonModel::Types::Bool
end
