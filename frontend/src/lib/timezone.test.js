import { describe, it, expect } from 'vitest'
import { isoToZonedInput, zonedInputToIso, TIMEZONE_OPTIONS } from './timezone'

describe('isoToZonedInput', () => {
  it('converts a UTC instant to the wall-clock time it reads as in the given zone', () => {
    expect(isoToZonedInput('2026-07-15T12:00:00.000Z', 'America/New_York')).toBe('2026-07-15T08:00') // EDT, UTC-4
    expect(isoToZonedInput('2026-01-15T12:00:00.000Z', 'America/New_York')).toBe('2026-01-15T07:00') // EST, UTC-5
    expect(isoToZonedInput('2026-07-15T12:00:00.000Z', 'Asia/Tokyo')).toBe('2026-07-15T21:00') // no DST, UTC+9
  })

  it('returns an empty string for a falsy value', () => {
    expect(isoToZonedInput('', 'UTC')).toBe('')
    expect(isoToZonedInput(null, 'UTC')).toBe('')
  })
})

describe('zonedInputToIso', () => {
  it('converts a wall-clock time in the given zone to the correct UTC instant', () => {
    expect(zonedInputToIso('2026-07-15T08:00', 'America/New_York')).toBe('2026-07-15T12:00:00.000Z') // EDT
    expect(zonedInputToIso('2026-01-15T07:00', 'America/New_York')).toBe('2026-01-15T12:00:00.000Z') // EST
    expect(zonedInputToIso('2026-07-15T21:00', 'Asia/Tokyo')).toBe('2026-07-15T12:00:00.000Z')
  })

  it('returns null for a falsy value', () => {
    expect(zonedInputToIso('', 'UTC')).toBe(null)
    expect(zonedInputToIso(null, 'UTC')).toBe(null)
  })
})

describe('round-trip', () => {
  it('isoToZonedInput and zonedInputToIso invert each other across a DST boundary', () => {
    const zone = 'America/New_York'
    for (const iso of ['2026-07-15T12:00:00.000Z', '2026-01-15T12:00:00.000Z']) {
      expect(zonedInputToIso(isoToZonedInput(iso, zone), zone)).toBe(iso)
    }
  })
})

describe('TIMEZONE_OPTIONS', () => {
  it('includes real IANA zones with a value/label pair', () => {
    const tokyo = TIMEZONE_OPTIONS.find((o) => o.value === 'Asia/Tokyo')
    expect(tokyo).toBeTruthy()
    expect(tokyo.label).toContain('Asia/Tokyo')
  })

  it('includes UTC explicitly, even though Intl.supportedValuesOf omits it', () => {
    expect(TIMEZONE_OPTIONS.find((o) => o.value === 'UTC')).toBeTruthy()
  })

  it('has no duplicate values', () => {
    const values = TIMEZONE_OPTIONS.map((o) => o.value)
    expect(new Set(values).size).toBe(values.length)
  })
})
