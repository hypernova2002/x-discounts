interface CouponCodeGeneratePayloadArgs {
  mode: 'oneoff' | 'bulk'
  bulkMode: 'count' | 'customers'
  code?: string | null
  customerId?: string | null
  count?: number
  customerIds?: string[]
  prefix?: string | null
  suffix?: string | null
  maxRedemptions: number
}

export interface CouponCodeGeneratePayload {
  code?: string | null
  customer_id?: string | null
  prefix?: string | null
  suffix?: string | null
  max_redemptions: number
  count?: number
  customer_ids?: string[]
}

// Shapes a coupon-code generation request body from the UI's one-off/bulk mode
// selection — mirrors CouponCodeGenerateRequest's mutually exclusive
// code/count/customer_ids contract. Shared by the inline "create with codes"
// step on DiscountFormView and the standalone "Generate codes" dialog on
// DiscountDetailView, which previously duplicated this branching.
export function couponCodeGeneratePayload({
  mode,
  bulkMode,
  code,
  customerId,
  count,
  customerIds,
  prefix,
  suffix,
  maxRedemptions,
}: CouponCodeGeneratePayloadArgs): CouponCodeGeneratePayload {
  if (mode === 'oneoff') {
    return { code: code || null, customer_id: customerId || null, max_redemptions: maxRedemptions }
  }

  const base = { prefix: prefix || null, suffix: suffix || null, max_redemptions: maxRedemptions }
  return bulkMode === 'count' ? { ...base, count } : { ...base, customer_ids: customerIds }
}
