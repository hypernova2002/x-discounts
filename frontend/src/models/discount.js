import { z } from 'zod'
import { CampaignSchema } from '@/models/campaign'

// Response shape (DiscountEffectResource). Deliberately loose on `config` and
// `target_condition` — see the note on discountInputSchema below for why.
export const DiscountEffectSchema = z
  .object({
    id: z.string(),
    effect_type: z.string(),
    scope: z.string(),
    target_condition: z.unknown().nullable(),
    config: z.record(z.unknown()),
  })
  .passthrough()

// Response shape (DiscountResource). One schema covers all three kinds — Alba
// always serializes the same shape, with the two kind-specific keys the discount
// isn't null for. .passthrough() — drift safety net, not a strict boundary (see
// models/campaign.js for the rationale shared across models).
export const DiscountSchema = z
  .object({
    id: z.string(),
    key: z.string(),
    kind: z.enum(['promotion', 'coupon', 'loyalty']),
    name: z.string(),
    stackable: z.boolean(),
    refundable: z.boolean(),
    enabled: z.boolean(),
    created_at: z.string(),
    updated_at: z.string(),
    eligibility_condition: z.unknown(),
    effects: z.array(DiscountEffectSchema),
    promotion: z.record(z.unknown()).nullable(),
    coupon: z.record(z.unknown()).nullable(),
    loyalty: z.record(z.unknown()).nullable(),
    compatible_discounts: z.array(z.record(z.unknown())),
    coupon_code_stats: z.object({ total: z.number(), available: z.number() }).nullable(),
    campaign: CampaignSchema,
    max_redemptions: z.number().nullable(),
    max_redemptions_per_customer: z.number().nullable(),
    max_redemptions_per_day: z.number().nullable(),
    max_redemption_amount: z.number().nullable(),
    max_redemption_amount_per_day: z.number().nullable(),
    max_redemption_amount_per_customer: z.number().nullable(),
  })
  .passthrough()

export const DiscountListSchema = z.object({ discounts: z.array(DiscountSchema) }).passthrough()

// Fields shared by all three kinds. `effects` and `eligibility_condition` are
// deliberately untyped here (z.unknown()/z.array(z.unknown())) rather than a full
// nested discriminated union replicating the 7 effect-config shapes and the
// recursive condition-tree grammar — ConditionTreeEditor.vue and EffectEditor.vue
// already manage that internal consistency, and the backend fully validates it
// server-side regardless. The value of client-side validation here is catching
// obviously-missing top-level fields fast, not re-implementing that polymorphism.
function baseDiscountFields(t) {
  return {
    key: z.string().nullable().optional(),
    name: z.string().min(1, t('discountForm.nameRequired')),
    // .nullable() rather than a bare required string — the Select this is bound to
    // has no selection as `null`, not `''`, and .min(1) alone would surface a generic
    // "expected string, received null" type error instead of this message.
    campaign_id: z.string().nullable().refine((v) => !!v, { message: t('discountForm.campaignRequired') }),
    stackable: z.boolean(),
    refundable: z.boolean(),
    enabled: z.boolean(),
    eligibility_condition: z.unknown().nullable().optional(),
    effects: z.array(z.unknown()),
    max_redemptions: z.number().nullable().optional(),
    max_redemptions_per_customer: z.number().nullable().optional(),
    max_redemptions_per_day: z.number().nullable().optional(),
    max_redemption_amount: z.number().nullable().optional(),
    max_redemption_amount_per_day: z.number().nullable().optional(),
    max_redemption_amount_per_customer: z.number().nullable().optional(),
  }
}

// Form input, one schema for both create and update — the `kind` select is
// disabled (not sent) on update, but the caller still includes the discount's
// current kind in the object it validates so the right branch is picked; strip
// `kind` back out of the payload before sending on update. `key` is required on
// update only (it's an immutable identifier once set, but auto-generated from
// `name` if left blank at creation) — pass `{ isEdit: true }` to enforce that.
export function discountInputSchema(t, { isEdit = false } = {}) {
  const base = baseDiscountFields(t)
  if (isEdit) base.key = z.string().nullable().refine((v) => !!v, { message: t('discountForm.keyRequired') })

  // A blank datetime-local input converts to `null` (see zonedInputToIso in
  // @/lib/timezone), not `''` — same reasoning as campaign_id/key above.
  const requiredActiveFrom = z.string().nullable().refine((v) => !!v, { message: t('discountForm.activeFromRequired') })

  return z.discriminatedUnion('kind', [
    z.object({
      kind: z.literal('promotion'),
      ...base,
      promotion: z.object({
        active_from: requiredActiveFrom,
        active_until: z.string().nullable().optional(),
      }),
    }),
    z.object({
      kind: z.literal('coupon'),
      ...base,
      coupon: z
        .object({
          issued_from: z.string().nullable().optional(),
          issued_until: z.string().nullable().optional(),
          valid_from: z.string().nullable().optional(),
          valid_until: z.string().nullable().optional(),
          code: z.string().nullable().optional(),
          customer_id: z.string().nullable().optional(),
          count: z.number().int().positive().max(5000).nullable().optional(),
          customer_ids: z.array(z.string()).optional(),
          prefix: z.string().nullable().optional(),
          suffix: z.string().nullable().optional(),
          max_redemptions: z.number().int().min(1).optional(),
        })
        // Unlike the standalone generate-codes flow (couponCodeGenerateInputSchema),
        // a coupon can be created with zero codes — so "none given" is valid here,
        // only "more than one mode given" is rejected.
        .refine((data) => [!!data.code, !!data.count, !!(data.customer_ids && data.customer_ids.length)].filter(Boolean).length <= 1, {
          message: t('couponCode.atMostOneModeError'),
        }),
    }),
    z.object({
      kind: z.literal('loyalty'),
      ...base,
      loyalty: z.object({
        active_from: requiredActiveFrom,
        active_until: z.string().nullable().optional(),
        points_expire_after_days: z.number().int().positive().nullable().optional(),
      }),
    }),
  ])
}
