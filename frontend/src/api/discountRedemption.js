import { apiFetch } from '@/lib/api'
import { ValidationResultSchema, RedemptionResultSchema } from '@/models/discountRedemption'

export function validateDiscounts(payload, { token, projectId }) {
  return apiFetch('/api/v1/discounts/validate', { method: 'POST', token, projectId, body: payload }).then((data) => ValidationResultSchema.parse(data))
}

export function redeemDiscounts(payload, { token, projectId }) {
  return apiFetch('/api/v1/discounts/redeem', { method: 'POST', token, projectId, body: payload }).then((data) => RedemptionResultSchema.parse(data))
}
