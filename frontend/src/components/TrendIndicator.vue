<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatPercent } from '@/lib/format'

// Renders nothing when there's no meaningful previous-period figure to compare
// against (spec: "avoid displaying a trend indicator when there is insufficient
// historical data") — a 0 -> N change is an undefined/infinite percentage, not
// a real trend. Every metric this app currently shows a trend for is a "more is
// better" one (redemptions, usage, earnings), so positive = success is a safe
// default rather than something each caller has to specify.
const props = defineProps({
  current: { type: Number, required: true },
  previous: { type: Number, default: null },
  caption: { type: String, required: true },
})

const { t } = useI18n()

const percentChange = computed(() => {
  if (!props.previous) return null
  return ((props.current - props.previous) / props.previous) * 100
})

const direction = computed(() => (percentChange.value >= 0 ? 'up' : 'down'))
</script>

<template>
  <p v-if="percentChange !== null" class="trend-indicator" :class="`trend-indicator--${direction}`">
    <i :class="direction === 'up' ? 'pi pi-arrow-up' : 'pi pi-arrow-down'" aria-hidden="true" />
    <span>{{ formatPercent(Math.abs(percentChange)) }}</span>
    <span class="trend-indicator__caption">{{ t('trendIndicator.vsCaption', { caption }) }}</span>
  </p>
</template>

<style scoped>
.trend-indicator {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  margin: 0;
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-medium);
}

.trend-indicator--up {
  color: var(--color-success);
}

.trend-indicator--down {
  color: var(--color-danger);
}

.trend-indicator__caption {
  color: var(--color-text-muted);
  font-weight: var(--font-weight-normal);
}
</style>
