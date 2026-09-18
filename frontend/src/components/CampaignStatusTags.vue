<script setup>
import BaseTag from '@/components/base/BaseTag.vue'

defineProps({ campaign: { type: Object, required: true } })
</script>

<template>
  <span class="inline-flex items-center gap-1.5">
    <BaseTag :severity="campaign.active ? 'success' : 'danger'" :value="campaign.active ? $t('campaignStatusTags.active') : $t('campaignStatusTags.inactive')" />
    <BaseTag v-if="!campaign.enabled" severity="secondary" :value="$t('campaignStatusTags.paused')" />
    <BaseTag v-if="campaign.archived" severity="secondary" :value="$t('campaignStatusTags.archived')" />
  </span>
</template>
