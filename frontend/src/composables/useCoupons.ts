import { ref } from 'vue'
import { apiFetch, type AuthParams } from '@/lib/api'
import type { Discount } from '@/models/discount'

// Module-level cache, same shape/pattern as useCustomAttributes — invalidated on
// project switch/logout in stores/auth.ts to avoid the same stale-cross-account bug.
const cache = ref<Discount[]>([])
const loaded = ref(false)
const loading = ref(false)

export function useCoupons() {
  async function load({ token, projectId }: AuthParams) {
    if (loaded.value || loading.value) return cache.value
    loading.value = true
    try {
      const data = (await apiFetch('/api/v1/admin/discounts?kind=coupon&per_page=500', { token, projectId })) as { discounts: Discount[] }
      cache.value = data.discounts
      loaded.value = true
      return cache.value
    } finally {
      loading.value = false
    }
  }
  function coupons() {
    return cache.value
  }
  function invalidate() {
    cache.value = []
    loaded.value = false
  }
  return { load, coupons, invalidate }
}
