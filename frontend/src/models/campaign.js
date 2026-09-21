import { z } from 'zod'

// Money fields are Postgres numeric columns — Rails serializes BigDecimal as a
// JSON string (same reasoning as the identical `money` type in models/order.js).
const money = z.union([z.number(), z.string()])

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const CampaignSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    enabled: z.boolean(),
    archived: z.boolean(),
    active: z.boolean(),
    valid_from: z.string().nullable(),
    valid_until: z.string().nullable(),
    created_at: z.string(),
    updated_at: z.string(),
    discount_kinds: z.array(z.enum(['promotion', 'coupon', 'loyalty'])),
    // Only present on campaigns#show (CampaignSummaryResource) — a real
    // aggregate query, deliberately left off the list response. See the
    // Phase 1 plan's backend section for why.
    discount_summary: z
      .object({ count: z.number(), redemption_count: z.number(), discounted_amount: money })
      .optional(),
  })
  .passthrough()

export const CampaignListSchema = z.object({ campaigns: z.array(CampaignSchema) }).passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (campaignForm.json).
// Shared by create and update — update applies .partial() at the call site.
export function campaignInputSchema(t) {
  return z.object({
    name: z.string().min(1, t('campaignForm.nameRequired')),
    enabled: z.boolean(),
    valid_from: z.string().nullable(),
    valid_until: z.string().nullable(),
  })
}
