# frozen_string_literal: true

class PointsFlatConfigRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :points, JsonModel::Types::Integer.constrained(gt: 0)
end
