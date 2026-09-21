<script setup>
import { useAttrs } from 'vue'
import ProgressBar from 'openvue/progressbar'

// Wraps OpenVue's ProgressBar (a determinate 0-100 usage bar) in unstyled
// mode. Same prop surface (value, mode, showValue) — import/tag swap only.
// `showValue` defaults to false here since callers needing a value label
// (e.g. "12 / 50") render their own text next to the bar rather than the
// library's built-in "%"-only overlay.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'h-1.5 w-full overflow-hidden rounded-full bg-bg-subtle',
  value: 'h-full rounded-full bg-primary transition-[width] duration-300',
}
</script>

<template>
  <ProgressBar unstyled :show-value="false" v-bind="attrs" :pt="pt" />
</template>
