# frozen_string_literal: true

class CustomerGrantPointsRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :points, JsonModel::Types::Integer
  attribute? :expires_at, JsonModel::Types::String.optional
  attribute? :reason, JsonModel::Types::String.optional
end
