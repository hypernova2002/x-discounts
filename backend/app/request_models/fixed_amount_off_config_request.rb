# frozen_string_literal: true

class FixedAmountOffConfigRequest < Dry::Struct
  include JsonModel::Schema

  PositiveAmount = (JsonModel::Types::Integer | JsonModel::Types::Float).constrained(gt: 0)

  transform_keys(&:to_sym)

  attribute :amount, PositiveAmount
  attribute :currency, JsonModel::Types::String.constrained(min_size: 1)
end
