<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'
import type { Discount } from '@/models/discount'

const props = defineProps<{ kind: Discount['kind'] }>()

const { t } = useI18n()

const SEVERITY: Record<Discount['kind'], string> = { coupon: 'info', promotion: 'success', loyalty: 'warn' }
const LABEL_KEY: Record<Discount['kind'], string> = { coupon: 'discountForm.kindCoupon', promotion: 'discountForm.kindPromotion', loyalty: 'discountForm.kindLoyalty' }

const label = computed(() => t(LABEL_KEY[props.kind]))
</script>

<template>
  <BaseTag :severity="SEVERITY[kind]" :value="label" />
</template>
