<script setup>
import { computed, useAttrs } from 'vue'
import Select from 'openvue/select'

// Wraps OpenVue's Select in unstyled mode. Same prop surface (modelValue,
// options, optionLabel/optionValue, filter, invalid, disabled, ...) —
// converting a call site is an import/tag swap only.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const isInvalid = computed(() => attrs.invalid !== undefined && attrs.invalid !== false)

const rootClass = computed(() =>
  [
    // No border on the closed field by request — relies on background/hover/
    // focus-ring instead. The invalid state keeps a real border though: that's
    // a functional error signal (component-design.md: never color alone), not
    // decorative chrome, so it stays even though the default border doesn't.
    'has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-offset-1',
    'relative flex w-full items-center gap-2 rounded-sm bg-bg px-3 py-2 text-sm transition-colors cursor-pointer',
    'not-has-[[aria-disabled=true]]:hover:bg-bg-subtle',
    'has-[[aria-disabled=true]]:cursor-not-allowed has-[[aria-disabled=true]]:bg-bg-subtle has-[[aria-disabled=true]]:text-text-disabled',
    isInvalid.value ? 'border border-danger has-[:focus-visible]:ring-danger' : 'has-[:focus-visible]:ring-primary',
  ].join(' '),
)

const pt = computed(() => ({
  root: rootClass.value,
  label: 'flex-1 truncate text-sm text-text outline-none',
  clearIcon: 'h-4 w-4 shrink-0 text-text-muted hover:text-text cursor-pointer',
  dropdown: 'flex shrink-0 items-center justify-center text-text-muted',
  dropdownIcon: 'h-4 w-4',
  loadingIcon: 'h-4 w-4 animate-spin',
  overlay: 'z-50 mt-1 min-w-[10rem] rounded-md border border-border bg-bg py-1 shadow-md',
  header: 'flex items-center gap-2 border-b border-border p-2',
  // pcFilterContainer/pcFilter/pcFilterIconContainer render as nested
  // components (IconField/InputText/InputIcon) — each pt value must be an
  // object keyed by THAT component's own section names, not a class string.
  // Without pcFilterContainer's `relative`, the icon (absolutely positioned
  // via pcFilterIconContainer) has no positioning context to anchor to and
  // falls into normal block flow below the input instead of sitting inside
  // it — mirrors the same fix already applied in BaseMultiSelect.vue.
  pcFilterContainer: { root: 'relative flex-1' },
  pcFilter: {
    root: 'w-full rounded-sm border border-border bg-bg py-1.5 pl-3 pr-7 text-sm text-text focus:outline-none focus:ring-2 focus:ring-primary',
  },
  pcFilterIconContainer: { root: 'absolute right-2 top-1/2 -translate-y-1/2 text-text-muted' },
  filterIcon: 'h-4 w-4',
  listContainer: '',
  list: 'max-h-60 overflow-auto py-1',
  optionGroup: 'px-3 py-1.5 text-xs font-semibold uppercase tracking-wide text-text-muted',
  optionGroupLabel: '',
  option: [
    'flex items-center gap-2 px-3 py-2 text-sm text-text cursor-pointer',
    'data-[p-focused=true]:bg-primary-subtle',
    'data-[p-selected=true]:font-medium data-[p-selected=true]:text-primary',
    'data-[p-disabled=true]:opacity-50 data-[p-disabled=true]:pointer-events-none',
  ].join(' '),
  optionLabel: 'truncate',
  optionCheckIcon: 'h-4 w-4 text-primary mr-1',
  optionBlankIcon: 'h-4 w-4 mr-1',
  emptyMessage: 'px-3 py-2 text-sm text-text-muted',
}))
</script>

<template>
  <Select unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.value" #value="scope"><slot name="value" v-bind="scope" /></template>
    <template v-if="$slots.option" #option="scope"><slot name="option" v-bind="scope" /></template>
    <template v-if="$slots.footer" #footer="scope"><slot name="footer" v-bind="scope" /></template>
  </Select>
</template>
