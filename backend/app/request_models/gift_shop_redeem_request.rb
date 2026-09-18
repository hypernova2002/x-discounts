# frozen_string_literal: true

class GiftShopRedeemRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :customer_external_id, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :quantity, JsonModel::Types::Integer.constrained(gt: 0).default(1)
end
