# frozen_string_literal: true

class OrderCancelRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :refund, JsonModel::Types::Bool.default(false)
  attribute? :reason, JsonModel::Types::String.optional
end
