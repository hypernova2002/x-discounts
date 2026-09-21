<script setup>
import TrendIndicator from '@/components/TrendIndicator.vue'

// A subtle-surface summary card: big primary value, small muted label, optional
// caption underneath — per .claude/rules/component-design.md's card tokens
// (subtle background/border, clear primary-number hierarchy, smaller secondary
// label). `trend` (optional) is { current, previous, caption } — omit it for a
// metric that isn't period-scoped (e.g. a live "total X right now" count).
defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  caption: { type: String, default: '' },
  trend: { type: Object, default: null },
})
</script>

<template>
  <div class="metric-card">
    <p class="metric-card__label">{{ label }}</p>
    <p class="metric-card__value">{{ value }}</p>
    <p v-if="caption" class="metric-card__caption">{{ caption }}</p>
    <TrendIndicator v-if="trend" :current="trend.current" :previous="trend.previous" :caption="trend.caption" />
  </div>
</template>

<style scoped>
.metric-card {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  padding: 1rem;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
}

.metric-card__label {
  margin: 0;
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.metric-card__value {
  margin: 0;
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text);
  font-variant-numeric: tabular-nums;
}

.metric-card__caption {
  margin: 0;
  font-size: var(--font-size-xs);
  color: var(--color-text-muted);
}
</style>
