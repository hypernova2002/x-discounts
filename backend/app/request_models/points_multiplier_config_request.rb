# frozen_string_literal: true

class PointsMultiplierConfigRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :multiplier, (JsonModel::Types::Integer | JsonModel::Types::Float).constrained(gt: 1)
end
