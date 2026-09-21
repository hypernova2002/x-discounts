import { describe, it, expect } from 'vitest'
import { countryFlag, countryName } from './country'

describe('countryFlag', () => {
  it('builds a regional-indicator flag emoji from a 2-letter code', () => {
    expect(countryFlag('US')).toBe('🇺🇸')
    expect(countryFlag('jp')).toBe('🇯🇵')
  })

  it('returns null for a non-conforming value', () => {
    expect(countryFlag('United States')).toBeNull()
    expect(countryFlag('U')).toBeNull()
    expect(countryFlag('')).toBeNull()
    expect(countryFlag(null)).toBeNull()
  })
})

describe('countryName', () => {
  it('resolves a full country name from a 2-letter code', () => {
    expect(countryName('US')).toBe('United States')
    expect(countryName('jp')).toBe('Japan')
  })

  it('falls back to the raw value for something it cannot resolve', () => {
    expect(countryName('Not A Code')).toBe('Not A Code')
  })

  it('returns an empty string for a falsy value', () => {
    expect(countryName(null)).toBe('')
    expect(countryName('')).toBe('')
  })
})
