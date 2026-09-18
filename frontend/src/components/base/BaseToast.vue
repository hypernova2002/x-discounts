<script setup>
import { useAttrs } from 'vue'
import Toast from 'openvue/toast'

// Wraps OpenVue's Toast in unstyled mode. This is the global toast OUTLET —
// render it once (in App.vue). Actual toasts are triggered elsewhere through
// `useBaseToast()` (composables/useBaseToast.js); this component owns none
// of that logic, just the visual container.
//
// DOM tree: Portal > div.root (fixed-positioned by the component's own
// inline styles regardless of unstyled — `sx()` isn't gated by unstyled the
// way `cx()` is, so position/offsets keep working) > TransitionGroup
// (pt key 'transition') > one ToastMessage per active toast, each a plain
// nested div.message > div.messageContent > [span.messageIcon,
// div.messageText > span.summary + div.detail] > div.buttonContainer >
// button.closeButton > icon.closeIcon. ToastMessage is technically a
// component, but — like Menubar's MenubarSub — it's handed Toast's *whole*
// `pt` object unchanged, so its section names are just flat keys here too,
// no nested-object gotcha.
//
// `message`/`messageText`/`summary`/`detail`/`closeButton` each carry their
// own `data-p="<severity>"` attribute directly (info/success/warn/error/
// secondary/contrast) — `messageIcon` does not, so its severity coloring
// reads its own message's `data-p` back through a plain (unnamed — Toast
// has no other nested `group`) Tailwind group on `message`.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const SEVERITY_BORDER =
  'data-[p=success]:border-l-success data-[p=info]:border-l-info ' +
  'data-[p=warn]:border-l-warning data-[p=error]:border-l-danger data-[p=secondary]:border-l-border'
const SEVERITY_ICON =
  'group-data-[p=success]:text-success group-data-[p=info]:text-info ' +
  'group-data-[p=warn]:text-warning group-data-[p=error]:text-danger group-data-[p=secondary]:text-text-muted'

const pt = {
  root: 'fixed z-50 flex w-[22rem] max-w-[calc(100vw-2.5rem)] flex-col pointer-events-none',
  transition: 'flex flex-col gap-2',
  message: [
    'group pointer-events-auto rounded-md border border-border border-l-4 bg-bg p-3 shadow-md',
    SEVERITY_BORDER,
  ].join(' '),
  messageContent: 'flex items-start gap-2',
  messageIcon: ['mt-0.5 h-5 w-5 shrink-0 text-text-muted', SEVERITY_ICON].join(' '),
  messageText: 'flex flex-1 flex-col gap-0.5',
  summary: 'text-sm font-semibold text-text',
  detail: 'text-sm text-text-muted',
  buttonContainer: 'ml-2 shrink-0',
  closeButton: [
    'rounded-sm p-1 text-text-muted cursor-pointer transition-colors',
    'hover:bg-bg-subtle hover:text-text',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1',
  ].join(' '),
  closeIcon: 'h-4 w-4',
}
</script>

<template>
  <Toast unstyled v-bind="attrs" :pt="pt" />
</template>
