<script setup>
defineEmits(['click'])
</script>

<template>
  <a href="#" class="entity-link" @click.stop.prevent="$emit('click')"><slot /></a>
</template>

<style scoped>
.entity-link {
  color: var(--color-primary);
  text-decoration: none;
}

.entity-link:hover {
  text-decoration: underline;
}
</style>
