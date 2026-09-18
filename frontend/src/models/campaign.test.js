import { describe, it, expect } from 'vitest'
import { CampaignSchema, CampaignListSchema, campaignInputSchema } from './campaign'

const t = (key) => key

const validCampaign = {
  id: 'camp_abc123',
  name: 'Spring Sale',
  enabled: true,
  archived: false,
  active: true,
  valid_from: null,
  valid_until: null,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
}

describe('CampaignSchema', () => {
  it('parses a valid response', () => {
    expect(() => CampaignSchema.parse(validCampaign)).not.toThrow()
  })

  it('passes through fields it does not declare, rather than rejecting them', () => {
    const withExtra = { ...validCampaign, some_future_field: 'unexpected' }
    const parsed = CampaignSchema.parse(withExtra)
    expect(parsed.some_future_field).toBe('unexpected')
  })

  it('rejects a response missing a required field', () => {
    const { name, ...withoutName } = validCampaign
    expect(() => CampaignSchema.parse(withoutName)).toThrow()
  })
})

describe('CampaignListSchema', () => {
  it('parses a list response', () => {
    const parsed = CampaignListSchema.parse({ campaigns: [validCampaign] })
    expect(parsed.campaigns).toHaveLength(1)
  })
})

describe('campaignInputSchema', () => {
  it('accepts a valid form input', () => {
    const result = campaignInputSchema(t).safeParse({ name: 'New Campaign', enabled: true, valid_from: null, valid_until: null })
    expect(result.success).toBe(true)
  })

  it('rejects an empty name with the i18n key as the message', () => {
    const result = campaignInputSchema(t).safeParse({ name: '', enabled: true, valid_from: null, valid_until: null })
    expect(result.success).toBe(false)
    expect(result.error.issues[0].message).toBe('campaignForm.nameRequired')
  })
})
