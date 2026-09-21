# frozen_string_literal: true

class OtpEnableRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :code, JsonModel::Types::String.constrained(min_size: 1)
end
