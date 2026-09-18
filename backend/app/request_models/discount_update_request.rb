# frozen_string_literal: true

# Update requests dispatch on the existing discount's kind, not the request body — kind
# isn't itself patchable, so a client updating unrelated fields has no reason to send it.
class DiscountUpdateRequest
  def self.build(body, kind:)
    case kind
    when "promotion" then PromotionDiscountUpdateRequest.new(body)
    when "coupon" then CouponDiscountUpdateRequest.new(body)
    when "loyalty" then LoyaltyDiscountUpdateRequest.new(body)
    end
  end
end
