# frozen_string_literal: true

class AdminResetPasswordRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :password, JsonModel::Types::String.constrained(min_size: 1)
  attribute :password_confirmation, JsonModel::Types::String.constrained(min_size: 1)
end
