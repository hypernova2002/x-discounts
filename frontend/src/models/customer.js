import { z } from 'zod'
import { MembershipTierSchema } from '@/models/membershipTier'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
const customerFields = {
  id: z.string(),
  external_id: z.string(),
  name: z.string().nullable(),
  email: z.string().nullable(),
  phone_number: z.string().nullable(),
  country: z.string().nullable(),
  date_of_birth: z.string().nullable(),
  marketing_opt_in: z.boolean(),
  membership_tier_entered_at: z.string().nullable(),
  created_at: z.string(),
  updated_at: z.string(),
  metadata: z.record(z.string(), z.any()),
  membership_tier: MembershipTierSchema.nullable(),
}

// The base shape returned by list, and by the plain `update` (PATCH) endpoint.
export const CustomerSchema = z.object(customerFields).passthrough()

export const CustomerListSchema = z.object({ customers: z.array(CustomerSchema) }).passthrough()

const ActivityItemSchema = z.discriminatedUnion('type', [
  z
    .object({
      type: z.literal('order'),
      occurred_at: z.string(),
      order_id: z.string(),
      total_amount: z.string(),
      total_discount_amount: z.string(),
      total_points_earned: z.number(),
      total_points_redeemed: z.number(),
    })
    .passthrough(),
  z
    .object({
      type: z.literal('gift_shop_redemption'),
      occurred_at: z.string(),
      item_name: z.string(),
      quantity: z.number(),
      points_spent: z.number(),
    })
    .passthrough(),
  z
    .object({
      type: z.literal('membership'),
      occurred_at: z.string(),
      tier_name: z.string(),
      scheme_name: z.string(),
    })
    .passthrough(),
])

const LoyaltyPointLotSchema = z
  .object({
    id: z.string(),
    points: z.number(),
    points_remaining: z.number(),
    earned_at: z.string(),
    expires_at: z.string().nullable(),
    source: z.enum(['order', 'manual_grant', 'legacy_backfill', 'redemption_refund']),
    expired: z.boolean(),
    status: z.enum(['active', 'expired', 'cancelled']),
    order_id: z.string().nullable(),
    discount_name: z.string().nullable(),
    reason: z.string().nullable(),
    performed_by: z.string().nullable(),
  })
  .passthrough()

const CustomerStatsSchema = z
  .object({
    order_count: z.number(),
    total_spent: z.string(),
    total_discount: z.string(),
    total_points_earned: z.number(),
    total_points_redeemed: z.number(),
    total_points_expired: z.number(),
    points_balance: z.number(),
  })
  .passthrough()

// Returned by `show` and `grant_points` — the base fields plus stats/activity/
// loyalty history. NOTE: the plain `update` (PATCH) endpoint does NOT return
// this richer shape, only CustomerSchema — see api/customers.js.
export const CustomerDetailSchema = z
  .object({
    ...customerFields,
    stats: CustomerStatsSchema,
    activity: z.array(ActivityItemSchema),
    loyalty_point_lots: z.array(LoyaltyPointLotSchema),
  })
  .passthrough()

// Form input for the "grant points" dialog. A factory (not a module-level
// constant) so validation messages are real i18n keys from the caller's own
// namespace (customerDetail.json).
export function grantPointsInputSchema(t) {
  return z.object({
    points: z
      .number({ message: t('customerDetail.grantDialog.pointsInvalid') })
      .int(t('customerDetail.grantDialog.pointsInvalid'))
      .gt(0, t('customerDetail.grantDialog.pointsInvalid')),
    expires_at: z.string().nullable(),
    reason: z.string().nullable(),
  })
}
