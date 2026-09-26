import { z } from 'zod'

const SeriesPointSchema = z.object({ date: z.string(), value: z.number() }).passthrough()

export const CouponAnalyticsSchema = z
  .object({
    summary: z.object({ total_coupons: z.number(), total_redemptions: z.number() }),
    series: z.array(SeriesPointSchema),
    previous_period: z.object({ total_redemptions: z.number() }),
  })
  .passthrough()

export const PromotionAnalyticsSchema = z
  .object({
    summary: z.object({ total_running_promotions: z.number(), total_discounts_from_promotions: z.number() }),
    usage_series: z.array(SeriesPointSchema),
    earnings_series: z.array(SeriesPointSchema),
    previous_period: z.object({ total_discounts_from_promotions: z.number() }),
  })
  .passthrough()

export const LoyaltyAnalyticsSchema = z
  .object({
    summary: z.object({ total_redemption_quantity: z.number(), total_points_redeemed: z.number() }),
    series: z.array(SeriesPointSchema),
    previous_period: z.object({ total_redemption_quantity: z.number(), total_points_redeemed: z.number() }),
  })
  .passthrough()

// Every summary/previous_period figure here is coerced with `.to_f` server-side
// (same reasoning as CustomerAnalyticsSchema's total_spent) — plain z.number(),
// not the string-tolerant `money` union other (non-analytics) schemas use.
export const CampaignAnalyticsSchema = z
  .object({
    summary: z.object({
      total_campaigns: z.number(),
      active_campaigns: z.number(),
      total_redemptions: z.number(),
      total_discounted_amount: z.number(),
    }),
    usage_series: z.array(SeriesPointSchema),
    earnings_series: z.array(SeriesPointSchema),
    previous_period: z.object({ total_redemptions: z.number(), total_discounted_amount: z.number() }),
  })
  .passthrough()

export const OrderAnalyticsSchema = z
  .object({
    summary: z.object({
      total_orders: z.number(),
      total_revenue: z.number(),
      total_discount_given: z.number(),
      average_order_value: z.number(),
    }),
    orders_series: z.array(SeriesPointSchema),
    revenue_series: z.array(SeriesPointSchema),
    previous_period: z.object({ total_orders: z.number(), total_revenue: z.number(), total_discount_given: z.number() }),
  })
  .passthrough()

export const CustomerAnalyticsSchema = z
  .object({
    summary: z.object({
      total_customers: z.number(),
      active_customers: z.number(),
      total_spent: z.number(),
      new_customers: z.number(),
    }),
    series: z.array(SeriesPointSchema),
    previous_period: z.object({ new_customers: z.number() }),
  })
  .passthrough()

const ActiveRedemptionSchema = z
  .object({
    id: z.string(),
    customer: z.object({ id: z.string(), external_id: z.string(), name: z.string().nullable() }),
    quantity: z.number(),
    expires_at: z.string().nullable(),
  })
  .passthrough()

export const ActiveLoyaltyRedemptionsSchema = z.object({ active_redemptions: z.array(ActiveRedemptionSchema) }).passthrough()

export const AttentionSchema = z
  .object({
    campaigns: z.array(z.object({ id: z.string(), name: z.string(), until: z.string() }).passthrough()),
    discounts: z.array(
      z
        .object({
          id: z.string(),
          name: z.string(),
          kind: z.enum(['promotion', 'coupon', 'loyalty']),
          until: z.string(),
          campaign: z.object({ id: z.string(), name: z.string() }),
        })
        .passthrough(),
    ),
  })
  .passthrough()
