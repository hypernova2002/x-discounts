import { ref, type Ref } from 'vue'

interface UseAsyncOptions {
  immediate?: boolean
}

interface UseAsyncReturn<T> {
  data: Ref<T | null>
  loading: Ref<boolean>
  error: Ref<unknown>
  reload: () => Promise<void>
}

// Wraps the loading/error/data triplet repeated across nearly every list and
// detail view. `fetchFn` is called with no arguments — close over whatever
// params it needs (e.g. a ref) at the call site so `reload()` re-reads their
// current value. Covers both list loads and single-resource loads; split into
// separate composables later only if a real behavioral divergence shows up.
export function useAsync<T>(fetchFn: () => Promise<T>, { immediate = true }: UseAsyncOptions = {}): UseAsyncReturn<T> {
  const data = ref<T | null>(null) as Ref<T | null>
  const loading = ref(false)
  const error = ref<unknown>(null)

  async function reload() {
    loading.value = true
    error.value = null
    try {
      data.value = await fetchFn()
    } catch (e) {
      error.value = e
    } finally {
      loading.value = false
    }
  }

  if (immediate) reload()

  return { data, loading, error, reload }
}
