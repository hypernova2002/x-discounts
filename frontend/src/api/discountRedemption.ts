import { apiFetch, type AuthParams } from '@/lib/api'
import { ValidationResultSchema, RedemptionResultSchema } from '@/models/discountRedemption'

export function validateDiscounts(payload: Record<string, unknown>, { token, projectId }: AuthParams) {
  return apiFetch('/api/v1/discounts/validate', { method: 'POST', token, projectId, body: payload }).then((data) => ValidationResultSchema.parse(data))
}

export function redeemDiscounts(payload: Record<string, unknown>, { token, projectId }: AuthParams) {
  return apiFetch('/api/v1/discounts/redeem', { method: 'POST', token, projectId, body: payload }).then((data) => RedemptionResultSchema.parse(data))
}
