# frozen_string_literal: true

# cart/line_items/customer stay as raw hashes (JsonModel::Types::Hash), not nested
# structs — a nested struct would only declare the fields it knows about and silently
# drop anything else, which would break eligibility checks against custom attributes
# the request model has no way to know about ahead of time.
class DiscountValidationRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :cart, JsonModel::Types::Hash.default({}.freeze)
  attribute? :line_items, JsonModel::Types::Array.of(JsonModel::Types::Hash).default([].freeze)
  attribute? :customer, JsonModel::Types::Hash.default({}.freeze)
  attribute? :coupon_codes, JsonModel::Types::Array.of(JsonModel::Types::String).default([].freeze)

  # How many loyalty points the customer wants to apply toward this order, at a 1
  # point = 1 currency unit ratio. Always clamped server-side (see ValidationService)
  # to the customer's actual balance and the remaining payable amount — never trusted
  # as-is.
  attribute? :redeem_points, JsonModel::Types::Integer.constrained(gteq: 0).default(0)

  # Validate-only: lets a caller preview a future or past-dated promotion/coupon
  # instead of always checking against the real current time. RedeemService never
  # reads this — an actual redemption always uses the real clock.
  attribute? :as_of, JsonModel::Types::String.optional
end
