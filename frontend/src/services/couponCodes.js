// Shapes a coupon-code generation request body from the UI's one-off/bulk mode
// selection — mirrors CouponCodeGenerateRequest's mutually exclusive
// code/count/customer_ids contract. Shared by the inline "create with codes"
// step on DiscountFormView and the standalone "Generate codes" dialog on
// DiscountDetailView, which previously duplicated this branching.
export function couponCodeGeneratePayload({ mode, bulkMode, code, customerId, count, customerIds, prefix, suffix, maxRedemptions }) {
  if (mode === 'oneoff') {
    return { code: code || null, customer_id: customerId || null, max_redemptions: maxRedemptions }
  }

  const base = { prefix: prefix || null, suffix: suffix || null, max_redemptions: maxRedemptions }
  return bulkMode === 'count' ? { ...base, count } : { ...base, customer_ids: customerIds }
}
