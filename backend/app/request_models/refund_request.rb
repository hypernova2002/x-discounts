# frozen_string_literal: true

# Both fields optional and mutually exclusive in practice — the caller sends whichever
# one is relevant to the line being refunded (amount_off for a plain discount, points
# for a loyalty discount or a points redemption). Omitting it entirely refunds
# whatever's left; Refunds::CreateService does the capping either way.
class RefundRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :amount_off, (JsonModel::Types::Integer | JsonModel::Types::Float).optional
  attribute? :points, JsonModel::Types::Integer.optional
  attribute? :reason, JsonModel::Types::String.optional
end
