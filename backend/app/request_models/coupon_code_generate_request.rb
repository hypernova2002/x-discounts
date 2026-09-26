# frozen_string_literal: true

# Exactly one of code/count/customer_ids:
# - code: a single one-off coupon with the exact string the admin chose (e.g. a
#   public, memorable "SAVE20"), optionally assigned to one customer.
# - count: that many auto-generated, unbound codes (anonymous bulk).
# - customer_ids: one auto-generated, customer-bound code per given customer
#   (personalized bulk).
# prefix/suffix only apply to auto-generated codes — independently optional, covering
# pure-random, prefix+random, random+suffix, and prefix+random+suffix.
class CouponCodeGenerateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :code, JsonModel::Types::String.optional
  attribute? :count, JsonModel::Types::Integer.constrained(gteq: 1, lteq: 10_000).optional
  attribute? :customer_ids, JsonModel::Types::Array.of(JsonModel::Types::String).optional
  attribute? :customer_id, JsonModel::Types::String.optional
  attribute? :prefix, JsonModel::Types::String.optional
  attribute? :suffix, JsonModel::Types::String.optional
  attribute? :max_redemptions, JsonModel::Types::Integer.constrained(gteq: 1).default(1)
end
