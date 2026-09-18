import { z } from 'zod'

// Response shape (CouponCodeResource). .passthrough() — drift safety net, not a
// strict boundary (see models/campaign.js for the rationale shared across models).
export const CouponCodeSchema = z
  .object({
    id: z.string(),
    code: z.string(),
    max_redemptions: z.number(),
    created_at: z.string(),
    redemption_count: z.number(),
    remaining_redemptions: z.number(),
    customer: z.object({ id: z.string(), external_id: z.string(), name: z.string().nullable() }).nullable(),
  })
  .passthrough()

export const CouponCodeListSchema = z.object({ coupon_codes: z.array(CouponCodeSchema) }).passthrough()

// The create (generate) endpoint renders a bare array, not { coupon_codes: [...] } —
// see CouponCodesController#create.
export const CouponCodeGenerateResponseSchema = z.array(CouponCodeSchema)

// Input for CouponCodes::GenerateService (see CouponCodeGenerateRequest's own
// comment): exactly one of code / count / customer_ids must be given — a manual
// one-off code, an anonymous bulk count, or one personalized code per customer.
// This mirrors that same shape used both by the standalone "Generate codes" dialog
// (DiscountDetailView) and inline coupon-code creation (DiscountFormView), which is
// why it lives here rather than as a one-off inline schema in either view.
export function couponCodeGenerateInputSchema(t) {
  return z
    .object({
      code: z.string().nullable().optional(),
      customer_id: z.string().nullable().optional(),
      count: z.number().int().positive().max(5000, t('couponCode.countMaxError')).nullable().optional(),
      customer_ids: z.array(z.string()).optional(),
      prefix: z.string().nullable().optional(),
      suffix: z.string().nullable().optional(),
      max_redemptions: z.number().int().min(1).optional(),
    })
    .refine((data) => [!!data.code, !!data.count, !!(data.customer_ids && data.customer_ids.length)].filter(Boolean).length === 1, {
      message: t('couponCode.exactlyOneModeError'),
    })
}
