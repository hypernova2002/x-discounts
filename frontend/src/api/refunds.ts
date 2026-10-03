import { apiFetch, type AuthParams } from '@/lib/api'
import type { RefundInput } from '@/models/refund'

export function refundDiscount(id: string, input: RefundInput, { token, projectId }: AuthParams) {
  return apiFetch(`/api/v1/admin/order_discounts/${id}/refund`, { method: 'POST', token, projectId, body: input })
}

export function refundPointsRedemption(id: string, input: RefundInput, { token, projectId }: AuthParams) {
  return apiFetch(`/api/v1/admin/points_redemptions/${id}/refund`, { method: 'POST', token, projectId, body: input })
}
