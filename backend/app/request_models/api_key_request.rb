# frozen_string_literal: true

class ApiKeyRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :user_id, JsonModel::Types::String
  attribute :role, JsonModel::Types::String.enum(*ProjectMembership::ROLES)
  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
end
