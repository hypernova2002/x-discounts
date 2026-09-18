import { describe, it, expect } from 'vitest'
import { couponCodeGeneratePayload } from './couponCodes'

describe('couponCodeGeneratePayload', () => {
  it('builds a one-off payload with a code and customer', () => {
    expect(
      couponCodeGeneratePayload({
        mode: 'oneoff',
        bulkMode: 'count',
        code: 'SAVE20',
        customerId: 'cust_123',
        count: 10,
        customerIds: [],
        prefix: '',
        suffix: '',
        maxRedemptions: 5,
      }),
    ).toEqual({ code: 'SAVE20', customer_id: 'cust_123', max_redemptions: 5 })
  })

  it('nulls out an unassigned customer in one-off mode', () => {
    const payload = couponCodeGeneratePayload({
      mode: 'oneoff',
      bulkMode: 'count',
      code: 'SAVE20',
      customerId: null,
      count: 10,
      customerIds: [],
      prefix: '',
      suffix: '',
      maxRedemptions: 1,
    })
    expect(payload.customer_id).toBeNull()
  })

  it('builds a bulk-count payload with prefix/suffix', () => {
    expect(
      couponCodeGeneratePayload({
        mode: 'bulk',
        bulkMode: 'count',
        code: '',
        customerId: null,
        count: 25,
        customerIds: [],
        prefix: 'WELCOME-',
        suffix: '',
        maxRedemptions: 1,
      }),
    ).toEqual({ prefix: 'WELCOME-', suffix: null, max_redemptions: 1, count: 25 })
  })

  it('builds a bulk-customers payload, omitting count', () => {
    const payload = couponCodeGeneratePayload({
      mode: 'bulk',
      bulkMode: 'customers',
      code: '',
      customerId: null,
      count: 25,
      customerIds: ['cust_1', 'cust_2'],
      prefix: '',
      suffix: '',
      maxRedemptions: 1,
    })
    expect(payload).toEqual({ prefix: null, suffix: null, max_redemptions: 1, customer_ids: ['cust_1', 'cust_2'] })
    expect(payload.count).toBeUndefined()
  })

  it('nulls empty prefix/suffix strings rather than sending blanks', () => {
    const payload = couponCodeGeneratePayload({
      mode: 'bulk',
      bulkMode: 'count',
      code: '',
      customerId: null,
      count: 5,
      customerIds: [],
      prefix: '',
      suffix: '',
      maxRedemptions: 1,
    })
    expect(payload.prefix).toBeNull()
    expect(payload.suffix).toBeNull()
  })
})
