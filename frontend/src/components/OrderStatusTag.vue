<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'

// Order#status (backend, computed from cancellation/refund state) — never a
// payment status, this app has no payment gateway or payment data at all.
const props = defineProps({ status: { type: String, required: true } })

const { t } = useI18n()

const SEVERITY = { active: 'success', cancelled: 'secondary', refunded: 'danger', partially_refunded: 'warn' }

const label = computed(() => t(`orders.status.${props.status}`))
</script>

<template>
  <BaseTag :severity="SEVERITY[status]" :value="label" />
</template>
