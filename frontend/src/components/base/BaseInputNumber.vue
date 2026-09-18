<script setup>
import { computed, useAttrs } from 'vue'
import InputNumber from 'openvue/inputnumber'

// Wraps OpenVue's InputNumber in unstyled mode. Same prop surface (modelValue,
// min/max, prefix/suffix, invalid, disabled, ...) — import/tag swap only.
// Internally InputNumber renders a nested (raw, non-Base) InputText for the
// actual <input> element — the `pcInputText` pt key targets that, not InputText's
// own `root` — so this mirrors BaseInputText's box styling on that key instead.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const isInvalid = computed(() => attrs.invalid !== undefined && attrs.invalid !== false)

const inputClass = computed(() =>
  [
    'w-full rounded-sm border bg-bg px-3 py-2 text-sm text-text transition-colors',
    'placeholder:text-text-disabled',
    'focus:outline-none focus:ring-2 focus:ring-offset-1',
    'disabled:bg-bg-subtle disabled:text-text-disabled disabled:cursor-not-allowed',
    isInvalid.value ? 'border-danger focus:ring-danger' : 'border-border focus:ring-primary',
  ].join(' '),
)

const pt = computed(() => ({
  root: 'relative inline-flex w-full items-center',
  // pcInputText renders as a nested <InputText> component, not a raw DOM node —
  // its pt value is forwarded as THAT component's own `pt` prop, so it must be
  // an object keyed by InputText's own section names (root), not a class string.
  pcInputText: { root: inputClass.value },
  clearIcon: 'text-text-muted hover:text-text cursor-pointer mr-2',
  buttonGroup: 'flex flex-col divide-y divide-border border border-l-0 border-border rounded-r-sm overflow-hidden',
  incrementButton: 'flex flex-1 items-center justify-center px-2 text-text-muted hover:bg-bg-subtle disabled:opacity-50 disabled:cursor-not-allowed',
  decrementButton: 'flex flex-1 items-center justify-center px-2 text-text-muted hover:bg-bg-subtle disabled:opacity-50 disabled:cursor-not-allowed',
}))
</script>

<template>
  <InputNumber unstyled v-bind="attrs" :pt="pt" />
</template>
