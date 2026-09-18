import { describe, it, expect } from 'vitest'
import { discountInputSchema } from './discount'

const t = (key) => key

const basePromotion = {
  kind: 'promotion',
  key: null,
  name: 'Adult fares off',
  campaign_id: 'camp_123',
  stackable: false,
  refundable: true,
  enabled: true,
  eligibility_condition: null,
  effects: [],
  max_redemptions: null,
  max_redemptions_per_customer: null,
  max_redemptions_per_day: null,
  max_redemption_amount: null,
  max_redemption_amount_per_day: null,
  max_redemption_amount_per_customer: null,
  promotion: { active_from: '2026-01-01T00:00:00Z', active_until: null },
}

describe('discountInputSchema — promotion kind', () => {
  it('accepts a valid promotion', () => {
    expect(discountInputSchema(t).safeParse(basePromotion).success).toBe(true)
  })

  it('rejects a missing name', () => {
    const result = discountInputSchema(t).safeParse({ ...basePromotion, name: '' })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'discountForm.nameRequired')).toBe(true)
  })

  it('rejects a missing campaign_id', () => {
    const result = discountInputSchema(t).safeParse({ ...basePromotion, campaign_id: null })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'discountForm.campaignRequired')).toBe(true)
  })

  it('rejects a missing promotion.active_from', () => {
    const result = discountInputSchema(t).safeParse({ ...basePromotion, promotion: { active_from: null, active_until: null } })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'discountForm.activeFromRequired')).toBe(true)
  })

  it('does not require key on create (isEdit: false, the default)', () => {
    expect(discountInputSchema(t).safeParse({ ...basePromotion, key: null }).success).toBe(true)
  })

  it('requires key when isEdit: true', () => {
    const result = discountInputSchema(t, { isEdit: true }).safeParse({ ...basePromotion, key: null })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'discountForm.keyRequired')).toBe(true)
  })
})

describe('discountInputSchema — coupon kind', () => {
  const baseCoupon = {
    ...basePromotion,
    kind: 'coupon',
    promotion: undefined,
    coupon: { issued_from: null, issued_until: null, valid_from: null, valid_until: null, code: null, customer_id: null, count: null, customer_ids: [], prefix: null, suffix: null, max_redemptions: 1 },
  }

  it('accepts a coupon created with zero codes (code/count/customer_ids all empty)', () => {
    expect(discountInputSchema(t).safeParse(baseCoupon).success).toBe(true)
  })

  it('accepts exactly one code-generation mode', () => {
    expect(discountInputSchema(t).safeParse({ ...baseCoupon, coupon: { ...baseCoupon.coupon, code: 'SAVE20' } }).success).toBe(true)
    expect(discountInputSchema(t).safeParse({ ...baseCoupon, coupon: { ...baseCoupon.coupon, count: 10 } }).success).toBe(true)
    expect(discountInputSchema(t).safeParse({ ...baseCoupon, coupon: { ...baseCoupon.coupon, customer_ids: ['cust_1'] } }).success).toBe(true)
  })

  it('rejects more than one code-generation mode given at once', () => {
    const result = discountInputSchema(t).safeParse({ ...baseCoupon, coupon: { ...baseCoupon.coupon, code: 'SAVE20', count: 10 } })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'couponCode.atMostOneModeError')).toBe(true)
  })
})

describe('discountInputSchema — loyalty kind', () => {
  const baseLoyalty = {
    ...basePromotion,
    kind: 'loyalty',
    promotion: undefined,
    loyalty: { active_from: '2026-01-01T00:00:00Z', active_until: null, points_expire_after_days: null },
  }

  it('accepts a valid loyalty discount', () => {
    expect(discountInputSchema(t).safeParse(baseLoyalty).success).toBe(true)
  })

  it('rejects a missing loyalty.active_from', () => {
    const result = discountInputSchema(t).safeParse({ ...baseLoyalty, loyalty: { ...baseLoyalty.loyalty, active_from: null } })
    expect(result.success).toBe(false)
  })
})

describe('discountInputSchema — deliberately loose fields', () => {
  it('accepts arbitrary effects/eligibility_condition shapes without validating their internals', () => {
    const result = discountInputSchema(t).safeParse({
      ...basePromotion,
      eligibility_condition: { operator: 'and', conditions: [{ entity: 'cart', key: 'channel', operator: 'eq', value: 'web' }] },
      effects: [{ effect_type: 'percentage_off', scope: 'cart', target_condition: null, config: { percentage: 10 } }],
    })
    expect(result.success).toBe(true)
  })

  it('rejects an unknown kind', () => {
    expect(discountInputSchema(t).safeParse({ ...basePromotion, kind: 'not_a_real_kind' }).success).toBe(false)
  })
})
