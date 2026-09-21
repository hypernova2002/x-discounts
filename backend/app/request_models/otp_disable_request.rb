# frozen_string_literal: true

class OtpDisableRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :current_password, JsonModel::Types::String.constrained(min_size: 1)
end
