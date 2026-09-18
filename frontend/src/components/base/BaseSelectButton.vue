<script setup>
import { useAttrs } from 'vue'
import SelectButton from 'openvue/selectbutton'

// Wraps OpenVue's SelectButton in unstyled mode. Same prop surface (modelValue,
// options, optionLabel/optionValue, multiple, disabled, ...) — import/tag swap
// only. Each option renders as a nested (raw) ToggleButton component, not a DOM
// node — `pcToggleButton`'s value is forwarded as THAT component's own `pt`
// prop, keyed by its own section names (root/content/label), not a class string.
// Selected state lives on the ToggleButton root's own `data-p-checked` attribute
// (no separate parent to read it from), so it's styled directly rather than via
// a group/peer variant.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'inline-flex overflow-hidden rounded-md border border-border',
  pcToggleButton: {
    root: [
      'inline-flex items-center justify-center px-3 py-2 text-sm font-medium transition-colors cursor-pointer',
      'bg-bg text-text border-r border-border last:border-r-0',
      'not-data-[p-checked=true]:hover:bg-bg-subtle',
      'data-[p-checked=true]:bg-primary-hover data-[p-checked=true]:text-white',
      'focus-visible:outline-none focus-visible:relative focus-visible:z-10 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1',
      'disabled:opacity-50 disabled:cursor-not-allowed',
    ].join(' '),
    content: 'inline-flex items-center gap-2',
    label: 'leading-none',
  },
}
</script>

<template>
  <SelectButton unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.option" #option="scope"><slot name="option" v-bind="scope" /></template>
  </SelectButton>
</template>
