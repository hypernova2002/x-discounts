import { describe, it, expect } from 'vitest'
import { deriveLifecycleStatus } from './lifecycleStatus'

const t = (key, params) => {
  if (key === 'lifecycleStatus.starts') return `Starts ${params.date}`
  if (key === 'lifecycleStatus.ended') return `Ended ${params.date}`
  return key
}

const now = new Date('2026-09-21T12:00:00.000Z')

describe('deriveLifecycleStatus', () => {
  it('is archived regardless of dates', () => {
    const result = deriveLifecycleStatus({ enabled: true, archived: true, from: '2026-01-01T00:00:00.000Z', until: null, timezone: 'UTC', now, t })
    expect(result.state).toBe('archived')
  })

  it('is paused when disabled and not archived', () => {
    const result = deriveLifecycleStatus({ enabled: false, archived: false, from: null, until: null, timezone: 'UTC', now, t })
    expect(result.state).toBe('paused')
  })

  it('is pending when the start date is in the future', () => {
    const result = deriveLifecycleStatus({ enabled: true, archived: false, from: '2026-09-25T00:00:00.000Z', until: null, timezone: 'UTC', now, t })
    expect(result.state).toBe('pending')
    expect(result.contextLine).toBe('Starts Sep 25, 2026')
  })

  it('is expired when the end date is in the past', () => {
    const result = deriveLifecycleStatus({ enabled: true, archived: false, from: null, until: '2026-09-10T00:00:00.000Z', timezone: 'UTC', now, t })
    expect(result.state).toBe('expired')
    expect(result.contextLine).toBe('Ended Sep 10, 2026')
  })

  it('is active within the date window and shows the date range', () => {
    const result = deriveLifecycleStatus({
      enabled: true,
      archived: false,
      from: '2026-09-01T00:00:00.000Z',
      until: '2026-09-30T00:00:00.000Z',
      timezone: 'UTC',
      now,
      t,
    })
    expect(result.state).toBe('active')
    expect(result.contextLine).toBe('Sep 1–30, 2026')
  })

  it('is active with no dates at all', () => {
    const result = deriveLifecycleStatus({ enabled: true, archived: false, from: null, until: null, timezone: 'UTC', now, t })
    expect(result.state).toBe('active')
  })

  it('reports endsInDays only when active and close to the end', () => {
    const soon = deriveLifecycleStatus({
      enabled: true,
      archived: false,
      from: null,
      until: '2026-09-29T12:00:00.000Z',
      timezone: 'UTC',
      now,
      t,
    })
    expect(soon.endsInDays).toBe(8)

    const farAway = deriveLifecycleStatus({
      enabled: true,
      archived: false,
      from: null,
      until: '2026-12-31T00:00:00.000Z',
      timezone: 'UTC',
      now,
      t,
    })
    expect(farAway.endsInDays).toBeNull()
  })

  it('does not report endsInDays when pending or expired', () => {
    const pending = deriveLifecycleStatus({ enabled: true, archived: false, from: '2026-09-25T00:00:00.000Z', until: null, timezone: 'UTC', now, t })
    expect(pending.endsInDays).toBeNull()
  })
})
