<script setup>
import { useAttrs } from 'vue'
import Dialog from 'openvue/dialog'

// Wraps OpenVue's Dialog in unstyled mode. Same prop surface (visible, modal,
// header, closable, style, ...) — import/tag swap only. Escape-key dismissal
// (closeOnEscape, default true) and the close button (closable, default true)
// keep working automatically — restyled only, not rewired. Backdrop-click
// dismissal is NOT enabled here because it was never enabled at any existing
// call site (dismissableMask defaults to false upstream and none of them pass
// it) — preserving that, not introducing a new behavior during a restyle.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  mask: 'fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4',
  root: 'flex max-h-[90vh] w-full max-w-lg flex-col rounded-lg bg-bg shadow-lg',
  header: 'flex items-center justify-between gap-4 border-b border-border px-4 py-3',
  title: 'text-lg font-semibold text-text',
  headerActions: 'flex items-center gap-1',
  pcCloseButton: {
    root: 'rounded-sm p-1 text-text-muted hover:bg-bg-subtle hover:text-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary',
    icon: 'h-4 w-4',
  },
  content: 'flex-1 overflow-y-auto px-4 py-4 text-sm text-text',
  footer: 'flex items-center justify-end gap-2 border-t border-border px-4 py-3',
}
</script>

<template>
  <Dialog unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <slot />
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
  </Dialog>
</template>
