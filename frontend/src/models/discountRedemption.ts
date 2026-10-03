import { z } from 'zod'
import type { ComposerTranslation } from 'vue-i18n'

// cart/line_items/customer stay loosely typed passthrough objects, deliberately —
// see DiscountValidationRequest on the backend: the redemption flow accepts
// arbitrary custom-attribute keys it has no fixed schema for, so a strict shape
// here would fight that design. Only the handful of top-level fields that have
// real, fixed backend constraints get validated.
export function discountRedemptionInputSchema(t: ComposerTranslation) {
  return z.object({
    cart: z.record(z.string(), z.unknown()),
    line_items: z.array(z.record(z.string(), z.unknown())),
    customer: z.record(z.string(), z.unknown()),
    coupon_codes: z.array(z.string()),
    redeem_points: z
      .number({ message: t('orderForm.loyaltyPoints.invalidAmount') })
      .int(t('orderForm.loyaltyPoints.invalidAmount'))
      .nonnegative(t('orderForm.loyaltyPoints.invalidAmount')),
  })
}

export type DiscountRedemptionInput = z.infer<ReturnType<typeof discountRedemptionInputSchema>>

// Response shapes are intentionally loose — validate returns a preview shape,
// redeem returns a full Order plus coupon/points-redemption context — only the
// field(s) the views actually depend on are declared, everything else passes
// through untouched. Mirrors Discounts::ValidationService#call's shape; coupon
// entries reuse the same per-effect result shape as applicable_discounts.
const DiscountEffectResultSchema = z
  .object({
    discount_id: z.string(),
    kind: z.string(),
    key: z.string(),
    name: z.string(),
    effect_type: z.string(),
    amount_off: z.number().optional(),
    free_items: z.array(z.object({ sku: z.string(), quantity: z.number() })).optional(),
    // Present on loyalty_points.breakdown entries only (points-earning/
    // multiplier results), absent on discount results — see
    // Discounts::ValidationService#loyalty_result on the backend.
    points: z.number().optional(),
    multiplier: z.number().optional(),
  })
  .passthrough()

const CouponResultSchema = z
  .object({
    code: z.string(),
    valid: z.boolean(),
    reason: z.string().nullable(),
    discounts: z.array(DiscountEffectResultSchema),
  })
  .passthrough()

const LoyaltyPointsResultSchema = z
  .object({
    total_points: z.number(),
    base_points: z.number(),
    multiplier: z.number(),
    breakdown: z.array(DiscountEffectResultSchema),
  })
  .passthrough()

const PointsRedemptionResultSchema = z
  .object({
    requested: z.number(),
    applied: z.number(),
    amount_off: z.number(),
    balance: z.number(),
  })
  .passthrough()

export const ValidationResultSchema = z
  .object({
    applicable_discounts: z.array(DiscountEffectResultSchema),
    total_amount_off: z.number(),
    coupons: z.array(CouponResultSchema),
    loyalty_points: LoyaltyPointsResultSchema,
    points_redemption: PointsRedemptionResultSchema,
  })
  .passthrough()

export type ValidationResult = z.infer<typeof ValidationResultSchema>
export type DiscountEffectResult = z.infer<typeof DiscountEffectResultSchema>

export const RedemptionResultSchema = z.object({ id: z.string() }).passthrough()

export type RedemptionResult = z.infer<typeof RedemptionResultSchema>
