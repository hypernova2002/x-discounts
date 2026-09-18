<script setup>
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import { useAuthStore } from '@/stores/auth'
import { useCoupons } from '@/composables/useCoupons'

defineOptions({ name: 'CouponCodeSelect' })

const props = defineProps({
  modelValue: { type: String, default: null },
  excludeCodes: { type: Array, default: () => [] },
})
const emit = defineEmits(['update:modelValue'])

const auth = useAuthStore()
const { load, coupons } = useCoupons()
const { t } = useI18n()

watch(
  () => auth.project?.id,
  (projectId) => {
    if (projectId) load({ token: auth.token, projectId })
  },
  { immediate: true }
)

const options = computed(() =>
  coupons()
    .filter((d) => d.coupon?.code && !props.excludeCodes.includes(d.coupon.code))
    .map((d) => ({ label: t('couponCodeSelect.optionLabel', { code: d.coupon.code, name: d.name }), value: d.coupon.code }))
)
</script>

<template>
  <BaseSelect
    :model-value="modelValue"
    :options="options"
    option-label="label"
    option-value="value"
    :placeholder="t('couponCodeSelect.placeholder')"
    filter
    :filter-placeholder="t('couponCodeSelect.filterPlaceholder')"
    @update:model-value="(v) => emit('update:modelValue', v)"
  />
</template>
