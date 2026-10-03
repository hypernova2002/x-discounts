import { ref } from 'vue'
import { apiFetch, type AuthParams } from '@/lib/api'
import type { CustomAttribute } from '@/models/customAttribute'

// Module-level (not per-component) so every ConditionTreeEditor instance on the page
// shares one cache instead of each leaf node re-fetching the same entity's attributes.
const cache = ref<Record<string, CustomAttribute[]>>({})
const loading = ref<Record<string, boolean>>({})

export function useCustomAttributes() {
  async function load(entity: string, { token, projectId }: AuthParams) {
    if (!entity || cache.value[entity] || loading.value[entity]) return cache.value[entity] || []

    loading.value = { ...loading.value, [entity]: true }
    try {
      // per_page=500: this needs the entity's whole attribute list to filter client-side
      // in the condition editor's dropdown, not just the app's default 25-per-page slice.
      const data = (await apiFetch(`/api/v1/admin/custom_attributes?entity=${entity}&per_page=500`, { token, projectId })) as {
        custom_attributes: CustomAttribute[]
      }
      cache.value = { ...cache.value, [entity]: data.custom_attributes }
      return data.custom_attributes
    } finally {
      loading.value = { ...loading.value, [entity]: false }
    }
  }

  function attributesFor(entity: string) {
    return cache.value[entity] || []
  }

  function invalidate() {
    cache.value = {}
  }

  return { load, attributesFor, invalidate }
}
