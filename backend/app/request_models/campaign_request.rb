# frozen_string_literal: true

class CampaignRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :enabled, JsonModel::Types::Bool.default(true)
  attribute? :valid_from, JsonModel::Types::String.optional
  attribute? :valid_until, JsonModel::Types::String.optional
end
