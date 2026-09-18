<script setup>
import { computed, useAttrs } from 'vue'
import Tag from 'openvue/tag'

// Wraps OpenVue's Tag (status badge) in unstyled mode. Same prop surface
// (value, severity, rounded, icon) — import/tag swap only.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const SEVERITY = {
  success: 'bg-success-bg text-success-text',
  danger: 'bg-danger-bg text-danger-text',
  warn: 'bg-warning-bg text-warning-text',
  info: 'bg-info-bg text-info-text',
  secondary: 'bg-bg-subtle text-text-muted',
  contrast: 'bg-text text-bg',
}

const rootClass = computed(() => {
  const severity = attrs.severity ?? 'secondary'
  const rounded = attrs.rounded !== undefined && attrs.rounded !== false
  return [
    'inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium',
    rounded ? 'rounded-full' : 'rounded-sm',
    SEVERITY[severity] || SEVERITY.secondary,
  ].join(' ')
})

const pt = computed(() => ({ root: rootClass.value, icon: 'text-current', label: 'leading-none' }))
</script>

<template>
  <Tag unstyled v-bind="attrs" :pt="pt" />
</template>
