<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'
import { useAuthStore } from '@/stores/auth'
import { deriveLifecycleStatus } from '@/lib/lifecycleStatus'
import type { LifecycleState } from '@/lib/lifecycleStatus'

// Shared by campaigns (valid_from/valid_until) and every discount kind (their own
// validity fields, passed in as from/until by the caller) — see lib/lifecycleStatus.ts.
const props = withDefaults(
  defineProps<{
    enabled: boolean
    archived?: boolean
    from?: string | null
    until?: string | null
    // Compact renders just the badge (for table cells); full also shows the
    // date-range/"Starts"/"Ended"/"Ends in N days" context line underneath.
    compact?: boolean
  }>(),
  { archived: false, from: null, until: null, compact: false },
)

const auth = useAuthStore()
const { t } = useI18n()

const SEVERITY: Record<LifecycleState, string> = { pending: 'info', active: 'success', expired: 'secondary', paused: 'secondary', archived: 'secondary' }

const status = computed(() =>
  deriveLifecycleStatus({
    enabled: props.enabled,
    archived: props.archived,
    from: props.from,
    until: props.until,
    timezone: auth.project?.timezone,
    t,
  }),
)
</script>

<template>
  <span class="lifecycle-status" :class="{ 'lifecycle-status--compact': compact }">
    <BaseTag :severity="SEVERITY[status.state]" :value="t(`lifecycleStatus.${status.state}`)" />
    <template v-if="!compact">
      <span v-if="status.contextLine" class="lifecycle-status__context">{{ status.contextLine }}</span>
      <span v-if="status.endsInDays !== null" class="lifecycle-status__ends-in">
        {{ status.endsInDays === 0 ? t('lifecycleStatus.endsToday') : t('lifecycleStatus.endsInDays', { days: status.endsInDays }) }}
      </span>
    </template>
  </span>
</template>

<style scoped>
.lifecycle-status {
  display: inline-flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.25rem;
}

.lifecycle-status--compact {
  flex-direction: row;
  align-items: center;
}

.lifecycle-status__context,
.lifecycle-status__ends-in {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}
</style>
