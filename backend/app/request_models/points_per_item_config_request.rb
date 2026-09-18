# frozen_string_literal: true

class PointsPerItemConfigRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :points_per_item, JsonModel::Types::Integer.constrained(gt: 0)
end
