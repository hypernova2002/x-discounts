<script setup>
import { computed, useAttrs } from 'vue'
import InputText from 'openvue/inputtext'

// Wraps OpenVue's InputText in unstyled mode. Same prop surface (modelValue,
// invalid, disabled, plus any native <input> attribute like type/placeholder) —
// converting a call site is an import/tag swap only.
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
  <InputText unstyled v-bind="attrs" :pt="{ root: rootClass }" />
</template>
