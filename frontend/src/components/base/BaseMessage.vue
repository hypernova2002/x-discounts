<script setup>
import { computed, useAttrs } from 'vue'
import Message from 'openvue/message'

// Wraps OpenVue's Message (inline alert/validation banner) in unstyled mode.
// Same prop surface (severity, closable, life, ...) — import/tag swap only.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const SEVERITY = {
  error: 'bg-danger-bg border-danger text-danger-text',
  danger: 'bg-danger-bg border-danger text-danger-text',
  warn: 'bg-warning-bg border-warning text-warning-text',
  success: 'bg-success-bg border-success text-success-text',
  info: 'bg-info-bg border-info text-info-text',
  secondary: 'bg-bg-subtle border-border text-text-muted',
}

const rootClass = computed(() => {
  const severity = attrs.severity ?? 'info'
  return ['flex items-start gap-2 rounded-md border p-3 text-sm', SEVERITY[severity] || SEVERITY.info].join(' ')
})

const pt = computed(() => ({
  root: rootClass.value,
  content: 'flex items-start gap-2 flex-1',
  text: 'flex-1',
  closeButton: 'shrink-0 rounded-sm p-0.5 hover:bg-black/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary',
}))
</script>

<template>
  <Message unstyled v-bind="attrs" :pt="pt"><slot /></Message>
</template>
