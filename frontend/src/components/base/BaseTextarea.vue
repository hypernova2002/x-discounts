<script setup>
import { computed, useAttrs } from 'vue'
import Textarea from 'openvue/textarea'

// Wraps OpenVue's Textarea in unstyled mode. Same prop surface (modelValue,
// autoResize, rows, invalid, disabled, ...) — import/tag swap only. Renders as
// a single <textarea> (root only, no nested sections).
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const isInvalid = computed(() => attrs.invalid !== undefined && attrs.invalid !== false)

const rootClass = computed(() =>
  [
    'w-full rounded-sm border bg-bg px-3 py-2 text-sm text-text transition-colors',
    'placeholder:text-text-disabled',
    'focus:outline-none focus:ring-2 focus:ring-offset-1',
    'disabled:bg-bg-subtle disabled:text-text-disabled disabled:cursor-not-allowed',
    isInvalid.value ? 'border-danger focus:ring-danger' : 'border-border focus:ring-primary',
  ].join(' '),
)
</script>

<template>
  <Textarea unstyled v-bind="attrs" :pt="{ root: rootClass }" />
</template>
