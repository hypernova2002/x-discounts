<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'
import type { Order } from '@/models/order'

// Order#status (backend, computed from cancellation/refund state) — never a
// payment status, this app has no payment gateway or payment data at all.
const props = defineProps<{ status: Order['status'] }>()

const { t } = useI18n()

const SEVERITY: Record<Order['status'], string> = { active: 'success', cancelled: 'secondary', refunded: 'danger', partially_refunded: 'warn' }

const label = computed(() => t(`orders.status.${props.status}`))
</script>

<template>
  <BaseTag :severity="SEVERITY[status]" :value="label" />
</template>
