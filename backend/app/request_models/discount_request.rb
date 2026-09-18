# frozen_string_literal: true

# Discount create requests are kind-specific (PromotionDiscountRequest / CouponDiscountRequest /
# LoyaltyDiscountRequest) since each kind stores fundamentally different data. This picks the
# right struct based on the submitted "kind" and raises the same ValidationError shape as any
# other bad input for anything else.
class DiscountRequest
  def self.build(body)
    case body[:kind]
    when "promotion" then PromotionDiscountRequest.new(body)
    when "coupon" then CouponDiscountRequest.new(body)
    when "loyalty" then LoyaltyDiscountRequest.new(body)
    else raise ValidationError.new(details: [{ field: "kind", message: "must be one of promotion, coupon, loyalty" }])
    end
  end
end
