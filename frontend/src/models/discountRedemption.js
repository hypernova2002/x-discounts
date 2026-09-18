import { z } from 'zod'

// cart/line_items/customer stay loosely typed passthrough objects, deliberately —
// see DiscountValidationRequest on the backend: the redemption flow accepts
// arbitrary custom-attribute keys it has no fixed schema for, so a strict shape
// here would fight that design. Only the handful of top-level fields that have
// real, fixed backend constraints get validated.
export function discountRedemptionInputSchema(t) {
  return z.object({
    cart: z.record(z.unknown()),
    line_items: z.array(z.record(z.unknown())),
    customer: z.record(z.unknown()),
    coupon_codes: z.array(z.string()),
    redeem_points: z
      .number({ message: t('orderForm.loyaltyPoints.invalidAmount') })
      .int(t('orderForm.loyaltyPoints.invalidAmount'))
      .nonnegative(t('orderForm.loyaltyPoints.invalidAmount')),
  })
}

// Response shapes are intentionally loose — validate returns a preview shape,
// redeem returns a full Order plus coupon/points-redemption context — only the
// field(s) the views actually depend on are declared, everything else passes
// through untouched.
export const ValidationResultSchema = z.object({}).passthrough()
export const RedemptionResultSchema = z.object({ id: z.string() }).passthrough()
