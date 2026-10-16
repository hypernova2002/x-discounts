// @vitest-environment jsdom
// This store reads/writes localStorage directly (same as stores/auth.ts),
// which only exists as a global under jsdom — the rest of the suite runs in
// the lighter 'node' environment, so this file opts in on its own.
import { describe, it, expect, beforeEach } from 'vitest'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import { useDateRangeStore } from './dateRange'

const STORAGE_KEY = 'x-discounts.date-range'

describe('useDateRangeStore', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  it('starts with a null range when nothing is stored', () => {
    const store = useDateRangeStore()
    expect(store.range).toBeNull()
  })

  it('starts from a previously stored range', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ from: '2026-07-18', to: '2026-10-16' }))
    const store = useDateRangeStore()
    expect(store.range).toEqual({ from: '2026-07-18', to: '2026-10-16' })
  })

  it('ignores malformed stored JSON and starts null', () => {
    localStorage.setItem(STORAGE_KEY, '{not json')
    const store = useDateRangeStore()
    expect(store.range).toBeNull()
  })

  it('ignores a stored value missing from/to and starts null', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ from: '2026-07-18' }))
    const store = useDateRangeStore()
    expect(store.range).toBeNull()
  })

  it('persists a new range to localStorage', async () => {
    const store = useDateRangeStore()
    store.range = { from: '2026-09-01', to: '2026-09-30' }
    await nextTick()
    expect(JSON.parse(localStorage.getItem(STORAGE_KEY)!)).toEqual({ from: '2026-09-01', to: '2026-09-30' })
  })
})
