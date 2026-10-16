// @vitest-environment jsdom
// Mounting a real app (no @vue/test-utils in this repo) needs `document`,
// and the dateRange store reads/writes localStorage (only a global under
// jsdom) — the rest of the suite runs in the lighter 'node' environment, so
// this file opts into jsdom on its own.
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { createApp, nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import { createRouter, createMemoryHistory, type Router } from 'vue-router'
import { useSharedDateRange } from './useSharedDateRange'
import { useDateRangeStore } from '@/stores/dateRange'

async function setup(initialPath: string) {
  const pinia = createPinia()
  setActivePinia(pinia)

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: '/:pathMatch(.*)*', component: { template: '<div />' } }],
  })
  await router.push(initialPath)

  let range!: ReturnType<typeof useSharedDateRange>
  const app = createApp({
    setup() {
      range = useSharedDateRange()
      return () => null
    },
  })
  app.use(pinia)
  app.use(router)
  app.mount(document.createElement('div'))

  return { router, range }
}

describe('useSharedDateRange', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('seeds the store from a from/to query param present on mount', async () => {
    const { range } = await setup('/coupons?from=2026-07-18&to=2026-10-16')
    expect(range.value).toEqual({ from: '2026-07-18', to: '2026-10-16' })
    expect(useDateRangeStore().range).toEqual({ from: '2026-07-18', to: '2026-10-16' })
  })

  it('writes an existing store value into a route with no from/to query param', async () => {
    localStorage.setItem('x-discounts.date-range', JSON.stringify({ from: '2026-01-01', to: '2026-01-31' }))
    const { router } = await setup('/promotions')
    await nextTick()
    // The immediate watch fires router.replace() synchronously but doesn't await
    // it, so give its navigation a tick to actually resolve before asserting.
    await new Promise((resolve) => setTimeout(resolve, 0))
    expect(router.currentRoute.value.query).toEqual({ from: '2026-01-01', to: '2026-01-31' })
  })

  it('ignores malformed query values and falls back to the store', async () => {
    localStorage.setItem('x-discounts.date-range', JSON.stringify({ from: '2026-01-01', to: '2026-01-31' }))
    const { range } = await setup('/coupons?from=not-a-date&to=2026-10-16')
    expect(range.value).toEqual({ from: '2026-01-01', to: '2026-01-31' })
  })

  it('mirrors a later store change into the current route query, without duplicating identical writes', async () => {
    const { router, range } = await setup('/coupons')
    const replaceSpy = vi.spyOn(router, 'replace')
    const callsBefore = replaceSpy.mock.calls.length

    range.value = { from: '2026-09-01', to: '2026-09-30' }
    await nextTick()
    await (replaceSpy.mock.results[replaceSpy.mock.results.length - 1].value as ReturnType<Router['replace']>)

    expect(router.currentRoute.value.query).toEqual({ from: '2026-09-01', to: '2026-09-30' })

    const callsAfterFirstWrite = replaceSpy.mock.calls.length
    range.value = { from: '2026-09-01', to: '2026-09-30' }
    await nextTick()
    expect(replaceSpy.mock.calls.length).toBe(callsAfterFirstWrite)
    expect(callsAfterFirstWrite).toBeGreaterThan(callsBefore)
  })
})
