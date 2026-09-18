import { apiFetch } from '@/lib/api'

export function refundDiscount(id, input, { token, projectId }) {
  return apiFetch(`/api/v1/admin/order_discounts/${id}/refund`, { method: 'POST', token, projectId, body: input })
}

export function refundPointsRedemption(id, input, { token, projectId }) {
  return apiFetch(`/api/v1/admin/points_redemptions/${id}/refund`, { method: 'POST', token, projectId, body: input })
}
