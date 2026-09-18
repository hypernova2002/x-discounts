<script setup>
import { useAttrs } from 'vue'
import ToggleSwitch from 'openvue/toggleswitch'

// Wraps OpenVue's ToggleSwitch in unstyled mode. Same prop surface (modelValue,
// disabled, invalid, ...) — import/tag swap only. `slider`/`handle` only expose
// a combined `data-p` token string (no discrete data-p-checked of their own), so
// checked-state coloring reads the root's separate `data-p-checked` attribute
// through Tailwind's `group-data-*` variant instead.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'group relative inline-flex h-6 w-11 shrink-0 items-center rounded-full',
  input: 'peer absolute inset-0 z-10 m-0 h-full w-full cursor-pointer opacity-0 disabled:cursor-not-allowed',
  slider: [
    'pointer-events-none absolute inset-0 flex items-center rounded-full transition-colors',
    'bg-border group-data-[p-checked=true]:bg-primary',
    'peer-focus-visible:outline-none peer-focus-visible:ring-2 peer-focus-visible:ring-primary peer-focus-visible:ring-offset-1',
    'peer-disabled:opacity-50',
  ].join(' '),
  handle: [
    'pointer-events-none inline-block h-4 w-4 translate-x-1 rounded-full bg-white shadow transition-transform',
    'group-data-[p-checked=true]:translate-x-6',
  ].join(' '),
}
</script>

<template>
  <ToggleSwitch unstyled v-bind="attrs" :pt="pt" />
</template>
