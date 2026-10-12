import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { useSearchableOptions } from './useSearchableOptions'

interface Thing {
  id: string
  name: string
}

describe('useSearchableOptions', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('keeps a seeded record visible even when a search\'s results do not include it', async () => {
    const list = vi.fn().mockResolvedValue({ items: [{ id: '2', name: 'Other' }] })
    const { seed, search, options } = useSearchableOptions<Thing>(list, (t) => ({ label: t.name, value: t.id }))

    seed([{ id: '1', name: 'Seeded' }])
    await search('', {})

    expect(options.value).toEqual([
      { label: 'Seeded', value: '1' },
      { label: 'Other', value: '2' },
    ])
  })

  it('does not duplicate a seeded record once a search returns it for real', async () => {
    const list = vi.fn().mockResolvedValue({ items: [{ id: '1', name: 'Seeded' }] })
    const { seed, search, options } = useSearchableOptions<Thing>(list, (t) => ({ label: t.name, value: t.id }))

    seed([{ id: '1', name: 'Seeded' }])
    await search('seed', {})

    expect(options.value).toEqual([{ label: 'Seeded', value: '1' }])
  })

  it('debounces onFilter into a single search call', async () => {
    const list = vi.fn().mockResolvedValue({ items: [] })
    const { onFilter } = useSearchableOptions<Thing>(list, (t) => ({ label: t.name, value: t.id }))

    onFilter({ value: 'a' }, {})
    onFilter({ value: 'ab' }, {})
    onFilter({ value: 'abc' }, {})

    await vi.advanceTimersByTimeAsync(400)

    expect(list).toHaveBeenCalledOnce()
    expect(list).toHaveBeenCalledWith({ q: 'abc', perPage: 50 })
  })

  it('passes undefined for an empty query rather than an empty string', async () => {
    const list = vi.fn().mockResolvedValue({ items: [] })
    const { search } = useSearchableOptions<Thing>(list, (t) => ({ label: t.name, value: t.id }))

    await search('', {})

    expect(list).toHaveBeenCalledWith({ q: undefined, perPage: 50 })
  })

  it('tracks loading around the search call', async () => {
    let resolve!: (value: { items: Thing[] }) => void
    const list = vi.fn().mockReturnValue(new Promise((r) => { resolve = r }))
    const { search, loading } = useSearchableOptions<Thing>(list, (t) => ({ label: t.name, value: t.id }))

    const pending = search('', {})
    expect(loading.value).toBe(true)

    resolve({ items: [] })
    await pending

    expect(loading.value).toBe(false)
  })
})
