# frozen_string_literal: true

class OtpVerifyRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :otp_challenge_token, JsonModel::Types::String.constrained(min_size: 1)
  attribute :code, JsonModel::Types::String.constrained(min_size: 1)
end
