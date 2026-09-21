import { describe, it, expect, vi, afterEach } from 'vitest'
import {
  formatNumber,
  formatDate,
  formatDateTime,
  formatCurrency,
  formatPercent,
  formatDateRange,
  formatRelativeDateTime,
  formatAbbreviatedNumber,
  formatCalendarDate,
} from './format'

const t = (key, params) => {
  if (key === 'format.todayAt') return `Today, ${params.time}`
  if (key === 'format.yesterdayAt') return `Yesterday, ${params.time}`
  if (key === 'format.fullTimestamp') return `${params.date} at ${params.time}`
  return key
}

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

describe('formatCalendarDate', () => {
  it('formats a plain YYYY-MM-DD bucket date without any timezone shift', () => {
    expect(formatCalendarDate('2026-09-01')).toBe('Sep 1')
    expect(formatCalendarDate('2026-01-31')).toBe('Jan 31')
  })

  it('never shifts the day regardless of what local/system timezone the test runs in', () => {
    // The classic bug this guards against: new Date('2026-09-01') interpreted
    // as UTC midnight, then re-read in a negative-offset zone, would print
    // Aug 31 instead of Sep 1. formatCalendarDate must never do that.
    expect(formatCalendarDate('2026-01-01')).toBe('Jan 1')
    expect(formatCalendarDate('2026-12-31')).toBe('Dec 31')
  })

  it('returns an empty string for a falsy value', () => {
    expect(formatCalendarDate(null)).toBe('')
    expect(formatCalendarDate('')).toBe('')
  })
})

describe('formatAbbreviatedNumber', () => {
  it('abbreviates thousands and millions', () => {
    expect(formatAbbreviatedNumber(1200)).toBe('1.2K')
    expect(formatAbbreviatedNumber(12430)).toBe('12.4K')
    expect(formatAbbreviatedNumber(1200000)).toBe('1.2M')
  })

  it('leaves small numbers unabbreviated', () => {
    expect(formatAbbreviatedNumber(42)).toBe('42')
  })

  it('returns an empty string for null/undefined/empty', () => {
    expect(formatAbbreviatedNumber(null)).toBe('')
    expect(formatAbbreviatedNumber(undefined)).toBe('')
    expect(formatAbbreviatedNumber('')).toBe('')
  })
})

describe('formatCurrency', () => {
  it('formats as USD with 2 decimal places and thousands separators', () => {
    expect(formatCurrency(12430)).toBe('$12,430.00')
    expect(formatCurrency(19.5)).toBe('$19.50')
    expect(formatCurrency(0)).toBe('$0.00')
  })

  it('returns an empty string for null/undefined/empty', () => {
    expect(formatCurrency(null)).toBe('')
    expect(formatCurrency(undefined)).toBe('')
    expect(formatCurrency('')).toBe('')
  })
})

describe('formatPercent', () => {
  it('formats a plain percentage number with one decimal place', () => {
    expect(formatPercent(18.4)).toBe('18.4%')
    expect(formatPercent(0)).toBe('0.0%')
    expect(formatPercent(100)).toBe('100.0%')
  })

  it('returns an empty string for null/undefined/empty', () => {
    expect(formatPercent(null)).toBe('')
    expect(formatPercent(undefined)).toBe('')
    expect(formatPercent('')).toBe('')
  })
})

describe('formatDateRange', () => {
  it('formats a same-month range without spaces around the dash', () => {
    expect(formatDateRange('2026-09-01T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'UTC')).toBe('Sep 1–30, 2026')
  })

  it('formats a cross-month range with spaces around the dash', () => {
    expect(formatDateRange('2026-09-28T00:00:00.000Z', '2026-10-05T00:00:00.000Z', 'UTC')).toBe('Sep 28 – Oct 5, 2026')
  })

  it('formats a cross-year range showing the year on both sides', () => {
    expect(formatDateRange('2026-12-28T00:00:00.000Z', '2027-01-05T00:00:00.000Z', 'UTC')).toBe('Dec 28, 2026 – Jan 5, 2027')
  })

  it('formats a single date when the other side is missing', () => {
    expect(formatDateRange('2026-09-25T00:00:00.000Z', null, 'UTC')).toBe('Sep 25, 2026')
    expect(formatDateRange(null, '2026-09-10T00:00:00.000Z', 'UTC')).toBe('Sep 10, 2026')
  })

  it('returns an empty string when both sides are missing', () => {
    expect(formatDateRange(null, null, 'UTC')).toBe('')
  })

  it('formats a same-day range as a single date', () => {
    expect(formatDateRange('2026-09-01T00:00:00.000Z', '2026-09-01T00:00:00.000Z', 'UTC')).toBe('Sep 1, 2026')
  })
})

describe('formatRelativeDateTime', () => {
  afterEach(() => vi.useRealTimers())

  it('labels a timestamp from today', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-09-21T12:00:00.000Z'))
    const { short } = formatRelativeDateTime('2026-09-21T03:42:00.000Z', 'UTC', t)
    expect(short).toBe('Today, 3:42 AM')
  })

  it('labels a timestamp from yesterday', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-09-21T12:00:00.000Z'))
    const { short } = formatRelativeDateTime('2026-09-20T11:18:00.000Z', 'UTC', t)
    expect(short).toBe('Yesterday, 11:18 AM')
  })

  it('falls back to a full date for older timestamps', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-09-21T12:00:00.000Z'))
    const { short } = formatRelativeDateTime('2026-09-14T08:00:00.000Z', 'UTC', t)
    expect(short).toBe('Sep 14, 2026')
  })

  it('returns a full absolute timestamp including seconds and the zone', () => {
    const { full } = formatRelativeDateTime('2026-09-21T03:42:18.000Z', 'UTC', t)
    expect(full).toBe('September 21, 2026 at 3:42:18 AM UTC')
  })

  it('returns empty strings for a falsy value', () => {
    expect(formatRelativeDateTime(null, 'UTC', t)).toEqual({ short: '', full: '' })
  })
})
