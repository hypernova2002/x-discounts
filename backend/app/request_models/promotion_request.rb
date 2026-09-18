# frozen_string_literal: true

class PromotionRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :active_from, JsonModel::Types::String
  attribute? :active_until, JsonModel::Types::String.optional
end
