# frozen_string_literal: true

class SignupRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :account_name, JsonModel::Types::String.constrained(min_size: 1)
  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
  attribute :email, JsonModel::Types::String.constrained(min_size: 1)
  attribute :password, JsonModel::Types::String.constrained(min_size: 1)
  attribute :password_confirmation, JsonModel::Types::String.constrained(min_size: 1)
end
