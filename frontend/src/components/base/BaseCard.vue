<script setup>
import Card from 'openvue/card'

// Wraps OpenVue's Card in unstyled mode. Purely a structural/style container —
// same #header/#title/#subtitle/#content/#footer slots, no prop translation needed.
const pt = {
  root: 'rounded-md border border-border bg-bg shadow-sm',
  header: 'p-4 border-b border-border',
  body: 'p-4 flex flex-col gap-2',
  caption: 'flex flex-col gap-1',
  title: 'text-xl font-semibold text-text',
  subtitle: 'text-sm text-text-muted',
  content: 'text-sm text-text',
  footer: 'pt-2 flex items-center gap-2',
}
</script>

<template>
  <Card unstyled :pt="pt">
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <template v-if="$slots.title" #title><slot name="title" /></template>
    <template v-if="$slots.subtitle" #subtitle><slot name="subtitle" /></template>
    <template #content><slot name="content" /></template>
    <template v-if="$slots.footer" #footer><slot name="footer" /></template>
  </Card>
</template>
