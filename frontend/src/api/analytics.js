import { apiFetch } from '@/lib/api'
import {
  CouponAnalyticsSchema,
  PromotionAnalyticsSchema,
  LoyaltyAnalyticsSchema,
  ActiveLoyaltyRedemptionsSchema,
  CustomerAnalyticsSchema,
  CampaignAnalyticsSchema,
  OrderAnalyticsSchema,
} from '@/models/analytics'

const BASE = '/api/v1/admin/analytics'

function rangeQuery({ from, to }) {
  return `?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`
}

export function getCouponAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/coupons${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CouponAnalyticsSchema.parse(data))
}

export function getPromotionAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/promotions${rangeQuery({ from, to })}`, { token, projectId }).then((data) => PromotionAnalyticsSchema.parse(data))
}

export function getLoyaltyAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/loyalty${rangeQuery({ from, to })}`, { token, projectId }).then((data) => LoyaltyAnalyticsSchema.parse(data))
}

export function getActiveLoyaltyRedemptions({ token, projectId }) {
  return apiFetch(`${BASE}/loyalty/active_redemptions`, { token, projectId }).then((data) => ActiveLoyaltyRedemptionsSchema.parse(data))
}

export function getCustomerAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/customers${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CustomerAnalyticsSchema.parse(data))
}

export function getCampaignAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/campaigns${rangeQuery({ from, to })}`, { token, projectId }).then((data) => CampaignAnalyticsSchema.parse(data))
}

export function getOrderAnalytics({ from, to, token, projectId }) {
  return apiFetch(`${BASE}/orders${rangeQuery({ from, to })}`, { token, projectId }).then((data) => OrderAnalyticsSchema.parse(data))
}
