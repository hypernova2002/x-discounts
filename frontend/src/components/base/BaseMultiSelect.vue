<script setup>
import { computed, useAttrs } from 'vue'
import MultiSelect from 'openvue/multiselect'

// Wraps OpenVue's MultiSelect in unstyled mode. Same prop surface (modelValue,
// options, optionLabel/optionValue, filter, showToggleAll, display, invalid,
// disabled, ...) — import/tag swap only.
//
// Several pt sections render as nested (raw) components rather than DOM nodes —
// each of those values must be an object keyed by THAT component's own section
// names, not a class string:
//   - pcChip            -> Chip (root, label, removeIcon)
//   - pcHeaderCheckbox   -> Checkbox (root, input, box, icon) — the "select all"
//     control shown in the header whenever filter or showToggleAll(default true)
//     is active. `input` must stay covered (absolute+opacity-0) same as
//     BaseCheckbox — omitting it leaves the native checkbox visible unstyled,
//     sitting next to the custom box instead of overlaying it invisibly.
//   - pcOptionCheckbox   -> Checkbox (root, input, box, icon) — one per option row
//   - pcFilterContainer  -> IconField (root)
//   - pcFilter           -> InputText (root)
//   - pcFilterIconContainer -> InputIcon (root)
// The two Checkbox instances read their own `checked` state off their own root's
// `data-p-checked` attribute (mirrors BaseCheckbox), so each is styled with the
// same group/box pattern as BaseCheckbox rather than referencing a parent.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const isInvalid = computed(() => attrs.invalid !== undefined && attrs.invalid !== false)

const rootClass = computed(() =>
  [
    // No border on the closed field, matching BaseSelect — relies on
    // background/hover/focus-ring instead. The invalid state keeps a real
    // border though: that's a functional error signal, not decorative chrome.
    'has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-offset-1',
    'relative flex w-full items-center gap-2 rounded-sm bg-bg px-3 py-2 text-sm transition-colors cursor-pointer',
    'not-has-[[aria-disabled=true]]:hover:bg-bg-subtle',
    'has-[[aria-disabled=true]]:cursor-not-allowed has-[[aria-disabled=true]]:bg-bg-subtle has-[[aria-disabled=true]]:text-text-disabled',
    isInvalid.value ? 'border border-danger has-[:focus-visible]:ring-danger' : 'has-[:focus-visible]:ring-primary',
  ].join(' '),
)

const checkboxPt = {
  root: 'group relative inline-flex h-4 w-4 shrink-0 items-center justify-center',
  input: 'peer absolute inset-0 z-10 m-0 h-full w-full cursor-pointer opacity-0 disabled:cursor-not-allowed',
  box: [
    'flex h-4 w-4 items-center justify-center rounded-sm border bg-bg transition-colors',
    'border-border',
    'group-data-[p-checked=true]:border-primary group-data-[p-checked=true]:bg-primary',
  ].join(' '),
  icon: 'h-3 w-3 text-white',
}

const pt = computed(() => ({
  root: rootClass.value,
  labelContainer: 'flex-1 min-w-0 overflow-hidden',
  label: 'flex flex-wrap items-center gap-1 truncate text-sm text-text outline-none',
  chipItem: '',
  pcChip: {
    root: 'inline-flex items-center gap-1 rounded-full bg-primary-subtle px-2 py-0.5 text-xs font-medium text-primary',
    label: 'leading-none',
    removeIcon: 'h-3 w-3 cursor-pointer hover:opacity-70',
  },
  clearIcon: 'h-4 w-4 shrink-0 text-text-muted hover:text-text cursor-pointer',
  dropdown: 'flex shrink-0 items-center justify-center text-text-muted',
  dropdownIcon: 'h-4 w-4',
  loadingIcon: 'h-4 w-4 animate-spin',
  overlay: 'z-50 mt-1 min-w-[10rem] rounded-md border border-border bg-bg py-1 shadow-md',
  header: 'flex items-center gap-2 border-b border-border p-2',
  pcHeaderCheckbox: checkboxPt,
  pcFilterContainer: { root: 'relative flex-1' },
  pcFilter: {
    root: 'w-full rounded-sm border border-border bg-bg py-1.5 pl-3 pr-7 text-sm text-text focus:outline-none focus:ring-2 focus:ring-primary',
  },
  pcFilterIconContainer: { root: 'absolute right-2 top-1/2 -translate-y-1/2 text-text-muted' },
  filterIcon: 'h-4 w-4',
  listContainer: '',
  list: 'max-h-60 overflow-auto py-1',
  optionGroup: 'px-3 py-1.5 text-xs font-semibold uppercase tracking-wide text-text-muted',
  option: [
    'flex items-center gap-2 px-3 py-2 text-sm text-text cursor-pointer',
    'data-[p-focused=true]:bg-primary-subtle',
    'data-[p-disabled=true]:opacity-50 data-[p-disabled=true]:pointer-events-none',
  ].join(' '),
  pcOptionCheckbox: checkboxPt,
  optionLabel: 'truncate',
  emptyMessage: 'px-3 py-2 text-sm text-text-muted',
}))
</script>

<template>
  <MultiSelect unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.value" #value="scope"><slot name="value" v-bind="scope" /></template>
    <template v-if="$slots.option" #option="scope"><slot name="option" v-bind="scope" /></template>
    <template v-if="$slots.chip" #chip="scope"><slot name="chip" v-bind="scope" /></template>
    <template v-if="$slots.header" #header="scope"><slot name="header" v-bind="scope" /></template>
    <template v-if="$slots.footer" #footer="scope"><slot name="footer" v-bind="scope" /></template>
  </MultiSelect>
</template>
