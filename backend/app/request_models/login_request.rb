# frozen_string_literal: true

class LoginRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :email, JsonModel::Types::String.constrained(min_size: 1)
  attribute :password, JsonModel::Types::String.constrained(min_size: 1)
end
