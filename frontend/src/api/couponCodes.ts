import { apiFetch, type AuthParams } from '@/lib/api'
import { CouponCodeListSchema, CouponCodeGenerateResponseSchema } from '@/models/couponCode'
import type { CouponCodeGenerateInput } from '@/models/couponCode'

const BASE = (discountId: string) => `/api/v1/admin/discounts/${discountId}/coupon_codes`

interface ListCouponCodesParams extends AuthParams {
  discountId: string
  perPage?: number
}

export function listCouponCodes({ discountId, perPage, token, projectId }: ListCouponCodesParams) {
  const path = perPage ? `${BASE(discountId)}?per_page=${perPage}` : BASE(discountId)
  return apiFetch(path, { token, projectId }).then((data) => CouponCodeListSchema.parse(data).coupon_codes)
}

// Renders a bare array, not { coupon_codes: [...] } — see CouponCodesController#create.
export function generateCouponCodes(discountId: string, input: CouponCodeGenerateInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE(discountId), { method: 'POST', token, projectId, body: input }).then((data) => CouponCodeGenerateResponseSchema.parse(data))
}

export function deleteCouponCode(discountId: string, codeId: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE(discountId)}/${codeId}`, { method: 'DELETE', token, projectId })
}
