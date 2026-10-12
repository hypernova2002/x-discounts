import { ref, shallowRef, computed } from 'vue'
import type { AuthParams } from '@/lib/api'

interface SearchableOption {
  label: string
  value: string
  [key: string]: unknown
}

// Backs a BaseSelect/BaseMultiSelect whose option list scales with real
// usage (campaigns, discounts, customers, ...) — fetches a small page via
// the backend's existing `q` search on every keystroke in the dropdown's
// own filter box, instead of loading up to the backend's 500-row cap once
// and filtering client-side (which silently truncates past 500).
//
// `seed` keeps an already-known record (e.g. one embedded via includes= in
// the parent fetch) visible even before any search runs, or if a later
// search's results don't happen to include it — otherwise a pre-existing
// selection would render blank once the full list is no longer loaded.
//
// `loading` is exposed for callers that want their own indicator, but don't
// wire it to BaseSelect/BaseMultiSelect's own `loading` prop — OpenVue's
// Select#onContainerClick silently no-ops a click while `loading` is true,
// so doing that can leave the dropdown unopenable (confirmed turning real,
// reproducible E2E flakiness) for however long a search is in flight,
// including the very first one on mount.
export function useSearchableOptions<T extends { id: string }>(
  list: (params: { q?: string; perPage?: number } & AuthParams) => Promise<{ items: T[] }>,
  toOption: (item: T) => SearchableOption,
) {
  const items = shallowRef<T[]>([])
  const seeded = shallowRef<T[]>([])
  const loading = ref(false)
  let debounceTimer: ReturnType<typeof setTimeout> | undefined

  const records = computed<T[]>(() => [...seeded.value.filter((s) => !items.value.some((i) => i.id === s.id)), ...items.value])
  const options = computed(() => records.value.map((record) => toOption(record)))

  async function search(q: string, authParams: AuthParams) {
    loading.value = true
    try {
      items.value = (await list({ q: q || undefined, perPage: 50, ...authParams })).items
    } finally {
      loading.value = false
    }
  }

  function onFilter(event: { value: string }, authParams: AuthParams) {
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => search(event.value, authParams), 400)
  }

  function seed(recordsToKeep: T[]) {
    seeded.value = recordsToKeep
  }

  return { records, options, loading, search, onFilter, seed }
}
