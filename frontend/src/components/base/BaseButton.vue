<script setup>
import { computed, useAttrs } from 'vue'
import Button from 'openvue/button'

// Wraps OpenVue's Button in unstyled mode, styled via Tailwind through `pt`.
// Accepts the exact same props OpenVue's Button does (severity, text, outlined,
// size, loading, disabled, icon, ...) — a call site converts by swapping the
// import/tag only, no prop rewrites. See .claude/rules/component-design.md for
// the token/state rules this implements.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const severity = computed(() => attrs.severity ?? null)
const isText = computed(() => attrs.text !== undefined && attrs.text !== false)
const isOutlined = computed(() => attrs.outlined !== undefined && attrs.outlined !== false)
const size = computed(() => attrs.size ?? null)

const BASE =
  'inline-flex items-center justify-center gap-2 rounded-md font-medium ' +
  'transition-colors cursor-pointer select-none ' +
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 ' +
  'disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none'

const SIZE = {
  small: 'px-2.5 py-1 text-xs',
  large: 'px-5 py-2.5 text-base',
}
const DEFAULT_SIZE = 'px-3.5 py-1.5 text-sm'

function variantClasses() {
  const danger = severity.value === 'danger'
  const secondary = severity.value === 'secondary'

  if (isText.value) {
    if (danger) return 'bg-transparent text-danger hover:bg-danger/10 active:bg-danger/20'
    if (secondary) return 'bg-transparent text-text-muted hover:bg-bg-subtle active:bg-border'
    return 'bg-transparent text-primary hover:bg-primary-subtle active:bg-primary-subtle'
  }
  if (isOutlined.value) {
    if (danger) return 'bg-transparent border border-danger text-danger hover:bg-danger/10 active:bg-danger/20'
    return 'bg-transparent border border-primary text-primary hover:bg-primary-subtle active:bg-primary-subtle'
  }
  if (danger) return 'bg-danger text-white hover:bg-danger-hover active:bg-danger-hover'
  if (secondary) return 'bg-bg-subtle text-text border border-border hover:bg-border active:bg-border'
  return 'bg-primary text-white hover:bg-primary-hover active:bg-primary-active'
}

const rootClass = computed(() => [BASE, SIZE[size.value] || DEFAULT_SIZE, variantClasses()].join(' '))
</script>

<template>
  <Button unstyled v-bind="attrs" :pt="{ root: rootClass, icon: 'text-current', loadingIcon: 'animate-spin' }" />
</template>
