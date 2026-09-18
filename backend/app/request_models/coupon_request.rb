# frozen_string_literal: true

class CouponRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :issued_from, JsonModel::Types::String.optional
  attribute? :issued_until, JsonModel::Types::String.optional
  attribute? :valid_from, JsonModel::Types::String.optional
  attribute? :valid_until, JsonModel::Types::String.optional

  # All optional — a coupon can be created with zero codes and have them added later
  # via the dedicated coupon_codes endpoint. When given, this is the exact same
  # {code} / {count} / {customer_ids} shape as CouponCodeGenerateRequest, so
  # Coupons::CreateService just hands it straight to CouponCodes::GenerateService.
  attribute? :code, JsonModel::Types::String.optional
  attribute? :count, JsonModel::Types::Integer.optional
  attribute? :customer_ids, JsonModel::Types::Array.of(JsonModel::Types::String).optional
  attribute? :customer_id, JsonModel::Types::String.optional
  attribute? :prefix, JsonModel::Types::String.optional
  attribute? :suffix, JsonModel::Types::String.optional
  attribute? :max_redemptions, JsonModel::Types::Integer.constrained(gteq: 1).default(1)
end
