<script setup>
import { useAttrs } from 'vue'
import Checkbox from 'openvue/checkbox'

// Wraps OpenVue's Checkbox in unstyled mode. Same prop surface (modelValue,
// binary, value, indeterminate, disabled, invalid, ...) — import/tag swap only.
// Structure: root > input (the real, visually-hidden checkbox) + box (the
// visible square) > icon (Check/Minus svg, rendered only when checked/
// indeterminate) — so `box` carries the visual styling and needs
// `flex items-center justify-center` to center the nested icon. `checked`/
// `indeterminate` land only on root's own `data-p-checked`/`data-p-indeterminate`
// attributes (not on input or box), so box reads them via Tailwind's `group-data-*`
// variant off root, the same approach BaseToggleSwitch uses for its handle.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'group relative inline-flex h-4 w-4 shrink-0 items-center justify-center',
  input: 'peer absolute inset-0 z-10 m-0 h-full w-full cursor-pointer opacity-0 disabled:cursor-not-allowed',
  box: [
    'flex h-4 w-4 items-center justify-center rounded-sm border bg-bg transition-colors',
    'border-border',
    'group-data-[p-checked=true]:border-primary group-data-[p-checked=true]:bg-primary',
    'group-data-[p-indeterminate=true]:border-primary group-data-[p-indeterminate=true]:bg-primary',
    'peer-focus-visible:outline-none peer-focus-visible:ring-2 peer-focus-visible:ring-primary peer-focus-visible:ring-offset-1',
    'peer-disabled:opacity-50 peer-disabled:cursor-not-allowed',
    'peer-aria-invalid:border-danger',
  ].join(' '),
  icon: 'h-3 w-3 text-white',
}
</script>

<template>
  <Checkbox unstyled v-bind="attrs" :pt="pt" />
</template>
