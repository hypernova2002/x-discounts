<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseTag from '@/components/base/BaseTag.vue'

const props = defineProps({ kind: { type: String, required: true } })

const { t } = useI18n()

const SEVERITY = { coupon: 'info', promotion: 'success', loyalty: 'warn' }
const LABEL_KEY = { coupon: 'discountForm.kindCoupon', promotion: 'discountForm.kindPromotion', loyalty: 'discountForm.kindLoyalty' }

const label = computed(() => t(LABEL_KEY[props.kind]))
</script>

<template>
  <BaseTag :severity="SEVERITY[kind]" :value="label" />
</template>
