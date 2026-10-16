import { watch, type Ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useRoute, useRouter } from 'vue-router'
import { useDateRangeStore } from '@/stores/dateRange'
import type { DateRange } from '@/components/DateRangePicker.vue'

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/

function readDate(value: unknown): string | null {
  const raw = Array.isArray(value) ? value[0] : value
  return typeof raw === 'string' && ISO_DATE.test(raw) ? raw : null
}

// The DateRangePicker v-model for every analytics view: backed by the shared
// dateRange store (so picking a range on one view shows it on another) and
// mirrored into the current route's from/to query params in both
// directions — a query param present on mount (e.g. a shared link) seeds
// the store and wins over whatever was in localStorage; otherwise the
// store's value is written into the URL, and kept there across navigation
// since this runs again on every view that calls it.
export function useSharedDateRange(): Ref<DateRange | null> {
  const route = useRoute()
  const router = useRouter()
  const store = useDateRangeStore()

  const queryFrom = readDate(route.query.from)
  const queryTo = readDate(route.query.to)
  if (queryFrom && queryTo) store.range = { from: queryFrom, to: queryTo }

  watch(
    () => store.range,
    (value) => {
      if (!value) return
      if (route.query.from === value.from && route.query.to === value.to) return
      router.replace({ query: { ...route.query, from: value.from, to: value.to } })
    },
    { immediate: true },
  )

  return storeToRefs(store).range
}
