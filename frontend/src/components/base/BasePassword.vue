<script setup>
import { computed, useAttrs } from 'vue'
import Password from 'openvue/password'

// Wraps OpenVue's Password in unstyled mode. Same prop surface (modelValue,
// feedback, toggleMask, showClear, invalid, disabled, ...) — import/tag swap only.
//
// DOM structure (verified against the real installed source, openvue/password):
//   root (div, relative)
//     pcInputText -> nested <InputText> component, not a raw DOM node — its pt
//       value must be an object keyed by InputText's own section names (root),
//       mirroring BaseInputText's box styling, not a class string.
//     maskIcon / unmaskIcon -> the reveal/hide toggle <button> (only one renders
//       at a time, based on toggleMask + unmasked state) — absolutely positioned
//       at the field's outer right edge, per the source's own default CSS.
//     clearIcon -> the clear <button> (only when showClear + filled + !disabled)
//       — positioned at the outer right edge too, but shifts further left, past
//       the toggle icon's slot, when toggleMask is also active (matches the
//       source's own `:has(.p-password-toggle-mask-icon)` shift rule).
//     hiddenAccesible -> sr-only live-region span announcing strength text.
//     overlay (via Portal, appendTo="body" by default) -> the feedback panel,
//       shown while focused when feedback is true (default true):
//       content > meter > meterLabel (width set inline by strength), meterText.
//   Neither call site in this app enables feedback (both pass :feedback="false"),
//   so the overlay/meter styling below is unverified against real rendered data —
//   built from the source's own class/structure, not guessed.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

// useAttrs() only camelCases a key when it matches one of THIS component's own
// declared props — since this wrapper declares none, multi-word attrs land
// exactly as written in the template (kebab-case, e.g. `toggle-mask` from
// `toggle-mask` / `:toggle-mask="..."`), not as `toggleMask`. Reading only the
// camelCase form here silently always evaluated false, which desynced this
// wrapper's own padding/icon-offset math from the real toggle/clear icons the
// underlying Password component was still correctly rendering — check both forms.
function boolAttr(camel, kebab) {
  const v = attrs[camel] !== undefined ? attrs[camel] : attrs[kebab]
  return v !== undefined && v !== false
}

const isInvalid = computed(() => attrs.invalid !== undefined && attrs.invalid !== false)
const hasToggle = computed(() => boolAttr('toggleMask', 'toggle-mask'))
const hasClear = computed(() => boolAttr('showClear', 'show-clear'))

const inputClass = computed(() =>
  [
    'w-full rounded-sm border bg-bg px-3 py-2 text-sm text-text transition-colors',
    'placeholder:text-text-disabled',
    'focus:outline-none focus:ring-2 focus:ring-offset-1',
    'disabled:bg-bg-subtle disabled:text-text-disabled disabled:cursor-not-allowed',
    isInvalid.value ? 'border-danger focus:ring-danger' : 'border-border focus:ring-primary',
    hasToggle.value && hasClear.value ? 'pr-16' : hasToggle.value || hasClear.value ? 'pr-9' : '',
  ].join(' '),
)

const ICON_BASE =
  'absolute top-1/2 -translate-y-1/2 flex h-4 w-4 items-center justify-center text-text-muted ' +
  'hover:text-text cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1 rounded-sm'

const toggleIconClass = computed(() => `${ICON_BASE} right-3`)
const clearIconClass = computed(() => `${ICON_BASE} ${hasToggle.value ? 'right-9' : 'right-3'}`)

const pt = computed(() => ({
  root: 'relative inline-flex w-full items-center',
  pcInputText: { root: inputClass.value },
  maskIcon: toggleIconClass.value,
  unmaskIcon: toggleIconClass.value,
  clearIcon: clearIconClass.value,
  overlay: 'z-50 min-w-full rounded-md border border-border bg-bg p-3 shadow-md',
  content: 'flex flex-col gap-2',
  meter: 'h-2 rounded-full bg-bg-subtle overflow-hidden',
  meterLabel: [
    'h-full rounded-full transition-[width] duration-500 ease-in-out',
    'data-[p=weak]:bg-danger data-[p=medium]:bg-warning data-[p=strong]:bg-success',
  ].join(' '),
  meterText: 'text-xs text-text-muted',
}))
</script>

<template>
  <Password unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
  </Password>
</template>
