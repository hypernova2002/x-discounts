# frozen_string_literal: true

class PercentageOffConfigRequest < Dry::Struct
  include JsonModel::Schema

  Percentage = (JsonModel::Types::Integer | JsonModel::Types::Float).constrained(gt: 0, lteq: 100)

  transform_keys(&:to_sym)

  attribute :percentage, Percentage
end
