import { z } from 'zod'

// Money fields are Postgres numeric columns — Rails serializes BigDecimal as a
// JSON string, but tolerate a plain number too since that's an implementation detail
// this schema shouldn't be brittle against.
const money = z.union([z.number(), z.string()])

const RefundHistoryEntrySchema = z
  .object({
    points: z.number().nullable(),
    amount_off: money.nullable(),
    refunded_at: z.string(),
    reason: z.string().nullable(),
    performed_by: z.string().nullable(),
  })
  .passthrough()

export const OrderCustomerSchema = z
  .object({
    id: z.string(),
    external_id: z.string(),
    name: z.string().nullable(),
    email: z.string().nullable(),
    phone_number: z.string().nullable(),
    country: z.string().nullable(),
  })
  .passthrough()

export const OrderLineItemSchema = z
  .object({
    sku: z.string(),
    quantity: z.number(),
    unit_price: money,
  })
  .passthrough()

export const OrderDiscountSchema = z
  .object({
    id: z.string(),
    kind: z.string(),
    sku: z.string().nullable(),
    discount_name: z.string(),
    effect_type: z.string().nullable(),
    amount_off: money.nullable(),
    points_earned: z.number().nullable(),
    refunded_amount_off: money.nullable(),
    refunded_points: z.number().nullable(),
    refundable: z.boolean().nullable(),
    free_items: z.array(z.unknown()).nullable(),
    refund_history: z.array(RefundHistoryEntrySchema),
  })
  .passthrough()

export const PointsRedemptionSchema = z
  .object({
    id: z.string(),
    points_redeemed: z.number(),
    amount_off: money,
    refunded_points: z.number(),
    refund_history: z.array(RefundHistoryEntrySchema),
  })
  .passthrough()

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const OrderSchema = z
  .object({
    id: z.string(),
    total_amount: money,
    total_discount_amount: money,
    total_points_earned: z.number(),
    cancelled_at: z.string().nullable(),
    created_at: z.string(),
    status: z.enum(['active', 'cancelled', 'refunded', 'partially_refunded']),
    customer: OrderCustomerSchema,
    line_items: z.array(OrderLineItemSchema),
    discounts: z.array(OrderDiscountSchema),
    points_redemption: PointsRedemptionSchema.nullable(),
  })
  .passthrough()

export const OrderListSchema = z.object({ orders: z.array(OrderSchema) }).passthrough()

// Cancel dialog input. Both fields are optional at the backend (see
// OrderCancelRequest) — validated here mainly for type/shape safety and to keep
// the submit flow consistent with the rest of the app's safeParse-before-submit
// pattern, not because either field can realistically be "invalid" from this UI.
export const OrderCancelInputSchema = z.object({
  refund: z.boolean(),
  reason: z.string().trim().nullable(),
})
