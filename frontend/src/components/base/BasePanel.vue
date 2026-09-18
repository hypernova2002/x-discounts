<script setup>
import { useAttrs } from 'vue'
import Panel from 'openvue/panel'

// Wraps OpenVue's Panel in unstyled mode. Same prop surface (header, toggleable,
// collapsed, toggleButtonProps, ...) — import/tag swap only. `pcToggleButton`
// renders as a nested (raw) Button component, not a DOM node — its pt value is
// forwarded as that component's own `pt` prop, keyed by Button's own section
// names (root, icon), mirroring BaseButton's `text` variant since the toggle
// button always renders as `severity: 'secondary', text: true, rounded: true`.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'rounded-md border border-border bg-bg shadow-sm',
  header: 'flex items-center justify-between gap-2 p-4',
  title: 'text-base font-semibold text-text',
  headerActions: 'flex items-center gap-1',
  pcToggleButton: {
    root: [
      'inline-flex h-7 w-7 items-center justify-center rounded-full text-text-muted transition-colors cursor-pointer',
      'hover:bg-bg-subtle active:bg-border',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1',
    ].join(' '),
    icon: 'h-4 w-4',
  },
  contentContainer: '',
  contentWrapper: '',
  content: 'p-4 pt-0',
  footer: 'border-t border-border px-4 py-3',
}
</script>

<template>
  <Panel unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.header" #header="scope"><slot name="header" v-bind="scope" /></template>
    <template v-if="$slots.icons" #icons><slot name="icons" /></template>
    <template v-if="$slots.togglebutton" #togglebutton="scope"><slot name="togglebutton" v-bind="scope" /></template>
    <slot />
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
  </Panel>
</template>
