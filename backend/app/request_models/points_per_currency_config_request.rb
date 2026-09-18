# frozen_string_literal: true

class PointsPerCurrencyConfigRequest < Dry::Struct
  include JsonModel::Schema

  PositiveRate = (JsonModel::Types::Integer | JsonModel::Types::Float).constrained(gt: 0)

  transform_keys(&:to_sym)

  attribute :rate, PositiveRate
end
