<script setup>
import { useAttrs, useTemplateRef } from 'vue'
import Popover from 'openvue/popover'

// Wraps OpenVue's Popover in unstyled mode. Same prop surface (dismissable,
// appendTo, closeOnEscape, ...) — import/tag swap only. Popover has no
// built-in trigger — callers hold a template ref and call `.toggle(event)`
// from their own button's click handler; that's forwarded here via
// defineExpose since Popover's own `toggle`/`show`/`hide` methods live on
// its component instance, not as props/emits.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()
const popoverRef = useTemplateRef('popoverRef')

function toggle(event) {
  popoverRef.value?.toggle(event)
}

defineExpose({ toggle })

const pt = {
  root: 'z-50 mt-2 rounded-md border border-border bg-bg shadow-md',
  content: '',
}
</script>

<template>
  <Popover ref="popoverRef" unstyled v-bind="attrs" :pt="pt">
    <slot />
  </Popover>
</template>
