import { apiFetch, apiUpload, type AuthParams } from '@/lib/api'
import { DiscountSchema, DiscountListSchema, type DiscountInput } from '@/models/discount'

const BASE = '/api/v1/admin/discounts'

interface ListDiscountsParams extends AuthParams {
  campaignId?: string
  kind?: string
  q?: string
  perPage?: number
}

export function listDiscounts({ campaignId, kind, q, perPage, token, projectId }: ListDiscountsParams = {}) {
  const params = new URLSearchParams()
  if (campaignId) params.set('campaign_id', campaignId)
  if (kind) params.set('kind', kind)
  if (q) params.set('q', q)
  if (perPage) params.set('per_page', String(perPage))
  const qs = params.toString()
  return apiFetch(qs ? `${BASE}?${qs}` : BASE, { token, projectId }).then((data) => DiscountListSchema.parse(data).discounts)
}

export function getDiscount(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => DiscountSchema.parse(data))
}

export function createDiscount(input: DiscountInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => DiscountSchema.parse(data))
}

export function updateDiscount(id: string, input: Partial<DiscountInput>, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => DiscountSchema.parse(data))
}

export function deleteDiscount(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'DELETE', token, projectId })
}

export function duplicateDiscount(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/duplicate`, { method: 'POST', token, projectId }).then((data) => DiscountSchema.parse(data))
}

export function uploadCouponDesignImage(id: string, file: File, { token, projectId }: AuthParams) {
  return apiUpload(`${BASE}/${id}/design_image`, { token, projectId, fieldName: 'design_image', file }).then((data) => DiscountSchema.parse(data))
}

// Explicit exceptions letting two otherwise-exclusive (stackable: false) discounts
// combine anyway — see Discounts::StackingResolver. Adding one returns the owning
// discount (with compatible_discounts refreshed); removing one returns no content.
export function addCompatibleDiscount(discountId: string, compatibleDiscountId: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${discountId}/compatible_discounts`, {
    method: 'POST',
    token,
    projectId,
    body: { compatible_discount_id: compatibleDiscountId },
  }).then((data) => DiscountSchema.parse(data))
}

export function removeCompatibleDiscount(discountId: string, compatibleDiscountId: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${discountId}/compatible_discounts/${compatibleDiscountId}`, { method: 'DELETE', token, projectId })
}
