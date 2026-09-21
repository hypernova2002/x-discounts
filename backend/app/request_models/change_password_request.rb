# frozen_string_literal: true

class ChangePasswordRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :current_password, JsonModel::Types::String.constrained(min_size: 1)
  attribute :new_password, JsonModel::Types::String.constrained(min_size: 1)
  attribute :new_password_confirmation, JsonModel::Types::String.constrained(min_size: 1)
end
