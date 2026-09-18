import { apiFetch } from '@/lib/api'
import { DiscountSchema, DiscountListSchema } from '@/models/discount'

const BASE = '/api/v1/admin/discounts'

export function listDiscounts({ campaignId, kind, q, perPage, token, projectId } = {}) {
  const params = new URLSearchParams()
  if (campaignId) params.set('campaign_id', campaignId)
  if (kind) params.set('kind', kind)
  if (q) params.set('q', q)
  if (perPage) params.set('per_page', perPage)
  const qs = params.toString()
  return apiFetch(qs ? `${BASE}?${qs}` : BASE, { token, projectId }).then((data) => DiscountListSchema.parse(data).discounts)
}

export function getDiscount(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => DiscountSchema.parse(data))
}

export function createDiscount(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => DiscountSchema.parse(data))
}

export function updateDiscount(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => DiscountSchema.parse(data))
}

export function deleteDiscount(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'DELETE', token, projectId })
}

// Explicit exceptions letting two otherwise-exclusive (stackable: false) discounts
// combine anyway — see Discounts::StackingResolver. Adding one returns the owning
// discount (with compatible_discounts refreshed); removing one returns no content.
export function addCompatibleDiscount(discountId, compatibleDiscountId, { token, projectId }) {
  return apiFetch(`${BASE}/${discountId}/compatible_discounts`, {
    method: 'POST',
    token,
    projectId,
    body: { compatible_discount_id: compatibleDiscountId },
  }).then((data) => DiscountSchema.parse(data))
}

export function removeCompatibleDiscount(discountId, compatibleDiscountId, { token, projectId }) {
  return apiFetch(`${BASE}/${discountId}/compatible_discounts/${compatibleDiscountId}`, { method: 'DELETE', token, projectId })
}
