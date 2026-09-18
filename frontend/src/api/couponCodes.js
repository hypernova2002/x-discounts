import { apiFetch } from '@/lib/api'
import { CouponCodeListSchema, CouponCodeGenerateResponseSchema } from '@/models/couponCode'

const BASE = (discountId) => `/api/v1/admin/discounts/${discountId}/coupon_codes`

export function listCouponCodes({ discountId, perPage, token, projectId }) {
  const path = perPage ? `${BASE(discountId)}?per_page=${perPage}` : BASE(discountId)
  return apiFetch(path, { token, projectId }).then((data) => CouponCodeListSchema.parse(data).coupon_codes)
}

// Renders a bare array, not { coupon_codes: [...] } — see CouponCodesController#create.
export function generateCouponCodes(discountId, input, { token, projectId }) {
  return apiFetch(BASE(discountId), { method: 'POST', token, projectId, body: input }).then((data) => CouponCodeGenerateResponseSchema.parse(data))
}

export function deleteCouponCode(discountId, codeId, { token, projectId }) {
  return apiFetch(`${BASE(discountId)}/${codeId}`, { method: 'DELETE', token, projectId })
}
