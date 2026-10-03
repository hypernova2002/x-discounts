<script setup lang="ts">
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import { useAuthStore } from '@/stores/auth'
import { useCoupons } from '@/composables/useCoupons'

defineOptions({ name: 'CouponCodeSelect' })

const props = withDefaults(
  defineProps<{
    modelValue?: string | null
    excludeCodes?: string[]
  }>(),
  { modelValue: null, excludeCodes: () => [] },
)
const emit = defineEmits<{ 'update:modelValue': [value: string | null] }>()

const auth = useAuthStore()
const { load, coupons } = useCoupons()
const { t } = useI18n()

watch(
  () => auth.project?.id,
  (projectId) => {
    if (projectId) load({ token: auth.token ?? undefined, projectId })
  },
  { immediate: true }
)

const options = computed(() =>
  coupons()
    .filter((d) => d.coupon?.code && !props.excludeCodes.includes(d.coupon.code as string))
    .map((d) => ({ label: t('couponCodeSelect.optionLabel', { code: d.coupon!.code as string, name: d.name }), value: d.coupon!.code as string }))
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
    @update:model-value="(v: string | null) => emit('update:modelValue', v)"
  />
</template>
