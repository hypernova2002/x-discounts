import { apiFetch, type AuthParams } from '@/lib/api'
import {
  CouponAnalyticsSchema,
  PromotionAnalyticsSchema,
  LoyaltyAnalyticsSchema,
  ActiveLoyaltyRedemptionsSchema,
  CustomerAnalyticsSchema,
  CampaignAnalyticsSchema,
  OrderAnalyticsSchema,
  AttentionSchema,
} from '@/models/analytics'

const BASE = '/api/v1/admin/analytics'

interface DateRange {
  from: string
  to: string
}

function rangeQuery({ from, to }: DateRange): string {
  return `?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`
}

interface AnalyticsRangeParams extends AuthParams, DateRange {}

export function getCouponAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/coupons${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CouponAnalyticsSchema.parse(data))
}

export function getPromotionAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/promotions${rangeQuery({ from, to })}`, { token, projectId }).then((data) => PromotionAnalyticsSchema.parse(data))
}

export function getLoyaltyAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/loyalty${rangeQuery({ from, to })}`, { token, projectId }).then((data) => LoyaltyAnalyticsSchema.parse(data))
}

interface ActiveLoyaltyRedemptionsParams extends AuthParams {
  page?: number
  perPage?: number
  q?: string
}

export function getActiveLoyaltyRedemptions({ page, perPage, q, token, projectId }: ActiveLoyaltyRedemptionsParams = {}) {
  const params = new URLSearchParams()
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  if (q) params.set('q', q)
  const qs = params.toString()
  return apiFetch(`${BASE}/loyalty/active_redemptions${qs ? `?${qs}` : ''}`, { token, projectId }).then((data) => ActiveLoyaltyRedemptionsSchema.parse(data))
}

export function getCustomerAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/customers${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CustomerAnalyticsSchema.parse(data))
}

export function getCampaignAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/campaigns${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CampaignAnalyticsSchema.parse(data))
}

export function getOrderAnalytics({ from, to, token, projectId }: AnalyticsRangeParams) {
  return apiFetch(`${BASE}/orders${rangeQuery({ from, to })}`, { token, projectId }).then((data) => OrderAnalyticsSchema.parse(data))
}

export function getAttentionItems({ token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/attention`, { token, projectId }).then((data) => AttentionSchema.parse(data))
}
