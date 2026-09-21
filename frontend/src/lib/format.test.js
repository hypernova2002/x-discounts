import { describe, it, expect } from 'vitest'
import { formatNumber, formatDate, formatDateTime } from './format'

describe('formatNumber', () => {
  it('drops a trailing .0 on whole numbers', () => {
    expect(formatNumber(50.0)).toBe('50')
    expect(formatNumber(0)).toBe('0')
  })

  it('adds thousands separators', () => {
    expect(formatNumber(1234)).toBe('1,234')
    expect(formatNumber(1234567.5)).toBe('1,234,567.5')
  })

  it('keeps up to 2 decimal places', () => {
    expect(formatNumber(19.99)).toBe('19.99')
    expect(formatNumber(19.999)).toBe('20')
  })

  it('returns an empty string for null/undefined/empty', () => {
    expect(formatNumber(null)).toBe('')
    expect(formatNumber(undefined)).toBe('')
    expect(formatNumber('')).toBe('')
  })
})

describe('formatDate', () => {
  it('formats as YYYY-MM-DD in local time', () => {
    const d = new Date(2026, 8, 5) // September 5, 2026 (local)
    expect(formatDate(d)).toBe('2026-09-05')
  })

  it('returns an empty string for a falsy value', () => {
    expect(formatDate(null)).toBe('')
    expect(formatDate('')).toBe('')
  })
})

describe('formatDateTime', () => {
  it('formats as YYYY-MM-DD HH:mm in local time', () => {
    const d = new Date(2026, 8, 5, 9, 5)
    expect(formatDateTime(d)).toBe('2026-09-05 09:05')
  })

  it('formats in the given IANA zone, not local time, with DST applied correctly', () => {
    const summer = '2026-07-15T12:00:00.000Z' // EDT (UTC-4)
    const winter = '2026-01-15T12:00:00.000Z' // EST (UTC-5)

    expect(formatDateTime(summer, 'America/New_York')).toBe('2026-07-15 08:00')
    expect(formatDateTime(winter, 'America/New_York')).toBe('2026-01-15 07:00')
    expect(formatDateTime(summer, 'Asia/Tokyo')).toBe('2026-07-15 21:00')
  })

  it('formats midnight as 00:00, not 24:00', () => {
    expect(formatDateTime('2026-07-15T00:00:00.000Z', 'UTC')).toBe('2026-07-15 00:00')
  })
})
