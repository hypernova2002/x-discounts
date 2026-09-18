import { describe, it, expect } from 'vitest'
import { couponCodeGenerateInputSchema } from './couponCode'

const t = (key) => key

const base = { code: null, customer_id: null, count: null, customer_ids: [], prefix: null, suffix: null, max_redemptions: 1 }

describe('couponCodeGenerateInputSchema — exactly one mode required', () => {
  it('accepts a one-off code', () => {
    expect(couponCodeGenerateInputSchema(t).safeParse({ ...base, code: 'SAVE20' }).success).toBe(true)
  })

  it('accepts a bulk count', () => {
    expect(couponCodeGenerateInputSchema(t).safeParse({ ...base, count: 25 }).success).toBe(true)
  })

  it('accepts personalized customer_ids', () => {
    expect(couponCodeGenerateInputSchema(t).safeParse({ ...base, customer_ids: ['cust_1', 'cust_2'] }).success).toBe(true)
  })

  it('rejects when nothing is given (unlike the create-time coupon schema, this dialog always generates something)', () => {
    const result = couponCodeGenerateInputSchema(t).safeParse(base)
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'couponCode.exactlyOneModeError')).toBe(true)
  })

  it('rejects when more than one mode is given', () => {
    const result = couponCodeGenerateInputSchema(t).safeParse({ ...base, code: 'SAVE20', count: 10 })
    expect(result.success).toBe(false)
    expect(result.error.issues.some((i) => i.message === 'couponCode.exactlyOneModeError')).toBe(true)
  })

  it('rejects a count above the 5000 cap', () => {
    const result = couponCodeGenerateInputSchema(t).safeParse({ ...base, count: 5001 })
    expect(result.success).toBe(false)
  })
})
