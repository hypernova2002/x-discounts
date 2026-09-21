<script setup>
import { computed } from 'vue'
import { countryFlag, countryName } from '@/lib/country'

const props = defineProps({ code: { type: String, default: null } })

const flag = computed(() => countryFlag(props.code))
const name = computed(() => countryName(props.code))
</script>

<template>
  <span v-if="flag" class="country-flag" v-tooltip.bottom="name">
    <span aria-hidden="true">{{ flag }}</span>
    <span class="country-flag__code">{{ code }}</span>
  </span>
  <!-- Falls back to plain text (no flag) for a value that doesn't look like a
       2-letter code — this app never validated Customer#country's format
       before now, so old/free-text data must never render broken. -->
  <span v-else-if="code">{{ code }}</span>
  <span v-else>—</span>
</template>

<style scoped>
.country-flag {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
}

.country-flag__code {
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
}
</style>
