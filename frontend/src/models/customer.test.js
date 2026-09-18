import { describe, it, expect } from 'vitest'
import { CustomerSchema, grantPointsInputSchema } from './customer'

const t = (key) => key

const validCustomer = {
  id: 'cust_abc',
  external_id: 'ext-1',
  name: null,
  email: null,
  phone_number: null,
  country: null,
  date_of_birth: null,
  marketing_opt_in: false,
  membership_tier_entered_at: null,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
  metadata: {},
  membership_tier: null,
}

describe('CustomerSchema', () => {
  it('parses a customer with no membership tier', () => {
    expect(() => CustomerSchema.parse(validCustomer)).not.toThrow()
  })

  // Regression test: a customer's membership tier with a null grace_period_days
  // (no grace period configured) previously crashed the whole Customers list —
  // models/customer.js had its own duplicate, stricter copy of the tier schema
  // instead of importing the shared one from models/membershipTier.js.
  it('parses a membership tier whose grace_period_days is null', () => {
    const customer = {
      ...validCustomer,
      membership_tier: {
        id: 'mtier_1',
        name: 'Bronze',
        rank: 1,
        grace_period_days: null,
        created_at: '2026-01-01T00:00:00Z',
        updated_at: '2026-01-01T00:00:00Z',
        requirements_condition: {},
        auto_assignable: false,
        membership_scheme: { id: 'mscheme_1', name: 'VIP Rewards' },
      },
    }
    expect(() => CustomerSchema.parse(customer)).not.toThrow()
  })

  it('still parses a tier with a real grace_period_days', () => {
    const customer = {
      ...validCustomer,
      membership_tier: {
        id: 'mtier_1',
        name: 'Gold',
        rank: 2,
        grace_period_days: 14,
        created_at: '2026-01-01T00:00:00Z',
        updated_at: '2026-01-01T00:00:00Z',
        requirements_condition: {},
        auto_assignable: true,
        membership_scheme: { id: 'mscheme_1', name: 'VIP Rewards' },
      },
    }
    const parsed = CustomerSchema.parse(customer)
    expect(parsed.membership_tier.grace_period_days).toBe(14)
  })
})

describe('grantPointsInputSchema', () => {
  it('accepts a positive integer points grant', () => {
    expect(grantPointsInputSchema(t).safeParse({ points: 100, expires_at: null, reason: null }).success).toBe(true)
  })

  it('rejects zero or negative points', () => {
    expect(grantPointsInputSchema(t).safeParse({ points: 0, expires_at: null, reason: null }).success).toBe(false)
    expect(grantPointsInputSchema(t).safeParse({ points: -5, expires_at: null, reason: null }).success).toBe(false)
  })

  it('rejects a non-integer points value', () => {
    expect(grantPointsInputSchema(t).safeParse({ points: 10.5, expires_at: null, reason: null }).success).toBe(false)
  })

  // Regression test for the zod v4 gotcha found this session: { invalid_type_error }
  // is silently ignored in v4, so a null/wrong-type value must still surface the
  // translated message via { message }, not zod's default English fallback.
  it('uses the translated message (not zod default English) when points is missing entirely', () => {
    const result = grantPointsInputSchema(t).safeParse({ points: null, expires_at: null, reason: null })
    expect(result.success).toBe(false)
    expect(result.error.issues[0].message).toBe('customerDetail.grantDialog.pointsInvalid')
  })
})
