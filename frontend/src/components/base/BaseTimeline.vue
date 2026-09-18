<script setup>
import { useAttrs } from 'vue'
import Timeline from 'openvue/timeline'

// Wraps OpenVue's Timeline in unstyled mode. Same prop surface (value, align,
// layout, dataKey) — import/tag swap only. All pt sections here are plain DOM
// elements (ol/li/div) per the real installed source — no nested components,
// unlike Password/InputNumber/MultiSelect.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const pt = {
  root: 'flex flex-col',
  event: 'relative flex gap-4 min-h-[3rem]',
  eventOpposite: 'flex-1 text-right pt-0.5',
  eventSeparator: 'flex flex-col items-center',
  eventMarker: 'mt-0.5 h-3 w-3 shrink-0 rounded-full border-2 border-primary bg-bg',
  eventConnector: 'w-px flex-1 bg-border',
  eventContent: 'flex-1 pb-4',
}
</script>

<template>
  <Timeline unstyled v-bind="attrs" :pt="pt">
    <template v-if="$slots.opposite" #opposite="scope"><slot name="opposite" v-bind="scope" /></template>
    <template v-if="$slots.marker" #marker="scope"><slot name="marker" v-bind="scope" /></template>
    <template v-if="$slots.connector" #connector="scope"><slot name="connector" v-bind="scope" /></template>
    <template #content="scope"><slot name="content" v-bind="scope" /></template>
  </Timeline>
</template>
