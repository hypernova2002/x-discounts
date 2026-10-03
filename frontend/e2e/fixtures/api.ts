import { test as base, expect, type APIRequestContext } from '@playwright/test'
import { readFixture } from './fixtureData'
import { uniqueSuffix } from '../support/unique'

export const API_BASE_URL = 'http://localhost:3001'

interface Fixtures {
  apiContext: APIRequestContext
}

// Extends the base `test` with an `apiContext` pre-authed as the E2E fixture's
// admin API key — specs use this to fast-create whatever a UI flow needs as a
// prerequisite (a campaign before a discount, a customer before an order),
// then drive the UI only for the behavior actually under test.
export const test = base.extend<Fixtures>({
  apiContext: async ({ playwright }, use) => {
    const fixture = readFixture()
    const context = await playwright.request.newContext({
      baseURL: API_BASE_URL,
      extraHTTPHeaders: {
        Authorization: `Bearer ${fixture.api_key}`,
        'X-Project-Id': fixture.project_id,
        'Content-Type': 'application/json',
      },
    })
    await use(context)
    await context.dispose()
  },
})

export { expect }

async function parse<T>(res: Awaited<ReturnType<APIRequestContext['post']>>, label: string): Promise<T> {
  if (!res.ok()) {
    throw new Error(`${label} failed: ${res.status()} ${await res.text()}`)
  }
  return res.json() as Promise<T>
}

export interface CampaignResource {
  id: string
  name: string
}

export async function createCampaign(api: APIRequestContext, overrides: Record<string, unknown> = {}): Promise<CampaignResource> {
  const res = await api.post('/api/v1/admin/campaigns', {
    data: { name: `E2E Campaign ${uniqueSuffix()}`, ...overrides },
  })
  return parse(res, 'createCampaign')
}

export interface DiscountEffectInput {
  effect_type: string
  scope: string
  target_condition?: unknown
  config: Record<string, unknown>
}

export interface DiscountResource {
  id: string
  key: string
  kind: string
  name: string
}

export async function createPromotionDiscount(
  api: APIRequestContext,
  campaignId: string,
  overrides: Record<string, unknown> = {},
): Promise<DiscountResource> {
  const res = await api.post('/api/v1/admin/discounts', {
    data: {
      kind: 'promotion',
      name: `E2E Promotion ${uniqueSuffix()}`,
      campaign_id: campaignId,
      promotion: { active_from: '2026-01-01T00:00:00Z' },
      effects: [{ effect_type: 'percentage_off', scope: 'cart', config: { percentage: 10 } }],
      ...overrides,
    },
  })
  return parse(res, 'createPromotionDiscount')
}

export async function createCouponDiscount(
  api: APIRequestContext,
  campaignId: string,
  overrides: Record<string, unknown> = {},
): Promise<DiscountResource> {
  const res = await api.post('/api/v1/admin/discounts', {
    data: {
      kind: 'coupon',
      name: `E2E Coupon ${uniqueSuffix()}`,
      campaign_id: campaignId,
      coupon: {},
      effects: [{ effect_type: 'fixed_amount_off', scope: 'cart', config: { amount: 5, currency: 'USD' } }],
      ...overrides,
    },
  })
  return parse(res, 'createCouponDiscount')
}

export async function createLoyaltyDiscount(
  api: APIRequestContext,
  campaignId: string,
  overrides: Record<string, unknown> = {},
): Promise<DiscountResource> {
  const res = await api.post('/api/v1/admin/discounts', {
    data: {
      kind: 'loyalty',
      name: `E2E Loyalty ${uniqueSuffix()}`,
      campaign_id: campaignId,
      loyalty: { active_from: '2026-01-01T00:00:00Z' },
      effects: [{ effect_type: 'points_per_currency', scope: 'cart', config: { rate: 1 } }],
      ...overrides,
    },
  })
  return parse(res, 'createLoyaltyDiscount')
}

export async function generateCouponCodes(api: APIRequestContext, discountId: string, overrides: Record<string, unknown> = {}) {
  const res = await api.post(`/api/v1/admin/discounts/${discountId}/coupon_codes`, {
    data: { count: 1, ...overrides },
  })
  return parse<unknown[]>(res, 'generateCouponCodes')
}

export async function addCompatibleDiscount(api: APIRequestContext, discountId: string, compatibleDiscountId: string) {
  const res = await api.post(`/api/v1/admin/discounts/${discountId}/compatible_discounts`, {
    data: { compatible_discount_id: compatibleDiscountId },
  })
  return parse(res, 'addCompatibleDiscount')
}

export interface CustomerResource {
  id: string
  external_id: string
}

export async function createCustomer(api: APIRequestContext, overrides: Record<string, unknown> = {}): Promise<CustomerResource> {
  const res = await api.post('/api/v1/admin/customers', {
    data: { external_id: `e2e-customer-${uniqueSuffix()}`, ...overrides },
  })
  return parse(res, 'createCustomer')
}

export async function grantPoints(api: APIRequestContext, customerId: string, points: number) {
  const res = await api.post(`/api/v1/admin/customers/${customerId}/grant_points`, { data: { points } })
  return parse(res, 'grantPoints')
}

export interface OrderLineItemInput {
  sku: string
  quantity: number
  unit_price: number
}

export interface OrderResource {
  id: string
  total: string
}

// Orders aren't created via the admin API (admin can only list/show/cancel
// them) — the real creation path is the storefront "redeem" endpoint, which
// is what OrderFormView.vue drives. Same auth (project-scoped Bearer token).
// A customer is always required — Discounts::RedeemService finds-or-creates
// one from `customer.external_id` unconditionally.
export async function createOrder(
  api: APIRequestContext,
  lineItems: OrderLineItemInput[],
  overrides: Record<string, unknown> = {},
): Promise<OrderResource> {
  const res = await api.post('/api/v1/discounts/redeem', {
    data: { line_items: lineItems, customer: { external_id: `e2e-order-customer-${uniqueSuffix()}` }, ...overrides },
  })
  return parse(res, 'createOrder')
}

export interface MembershipSchemeResource {
  id: string
  name: string
}

export async function createMembershipScheme(api: APIRequestContext, overrides: Record<string, unknown> = {}): Promise<MembershipSchemeResource> {
  const res = await api.post('/api/v1/admin/membership_schemes', {
    data: { name: `E2E Membership ${uniqueSuffix()}`, ...overrides },
  })
  return parse(res, 'createMembershipScheme')
}

export async function createMembershipTier(api: APIRequestContext, schemeId: string, overrides: Record<string, unknown> = {}) {
  const res = await api.post(`/api/v1/admin/membership_schemes/${schemeId}/tiers`, {
    data: { name: `E2E Tier ${uniqueSuffix()}`, rank: 1, ...overrides },
  })
  return parse(res, 'createMembershipTier')
}

export interface GiftShopItemResource {
  id: string
  name: string
}

export async function createGiftShopItem(api: APIRequestContext, overrides: Record<string, unknown> = {}): Promise<GiftShopItemResource> {
  const res = await api.post('/api/v1/admin/gift_shop_items', {
    data: { name: `E2E Gift Item ${uniqueSuffix()}`, points_cost: 100, ...overrides },
  })
  return parse(res, 'createGiftShopItem')
}

export interface CustomAttributeResource {
  id: string
  entity: string
  key: string
  data_type: string
}

export async function createCustomAttribute(api: APIRequestContext, overrides: Record<string, unknown> = {}): Promise<CustomAttributeResource> {
  const res = await api.post('/api/v1/admin/custom_attributes', {
    data: { entity: 'customer', key: `e2e_attr_${uniqueSuffix().replace(/-/g, '_')}`, data_type: 'string', ...overrides },
  })
  return parse(res, 'createCustomAttribute')
}
