<script setup>
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelectButton from '@/components/base/BaseSelectButton.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'

// v-model is { from, to } (ISO date strings, e.g. "2026-08-22") — shared across
// every analytics dashboard's date-range control (spec: "consistent date-range
// control... across analytics views"). Defaults to a 30-day trailing window on
// mount and emits immediately so the parent's first fetch has a real range.
const props = defineProps({ modelValue: { type: Object, default: null } })
const emit = defineEmits(['update:modelValue'])

const { t } = useI18n()

const PRESETS = computed(() => [
  { label: t('dateRangePicker.days7'), value: '7' },
  { label: t('dateRangePicker.days30'), value: '30' },
  { label: t('dateRangePicker.days90'), value: '90' },
  { label: t('dateRangePicker.custom'), value: 'custom' },
])

const preset = ref('30')
const customFrom = ref('')
const customTo = ref('')

function isoDate(date) {
  return date.toISOString().slice(0, 10)
}

function applyPreset(days) {
  const to = new Date()
  const from = new Date()
  from.setDate(from.getDate() - (Number(days) - 1))
  const range = { from: isoDate(from), to: isoDate(to) }
  customFrom.value = range.from
  customTo.value = range.to
  emit('update:modelValue', range)
}

function onPresetChange(value) {
  preset.value = value
  if (value !== 'custom') applyPreset(value)
}

function onCustomChange() {
  if (!customFrom.value || !customTo.value) return
  emit('update:modelValue', { from: customFrom.value, to: customTo.value })
}

const rangeLabel = computed(() => {
  if (!props.modelValue) return ''
  return t('dateRangePicker.rangeLabel', { from: props.modelValue.from, to: props.modelValue.to })
})

onMounted(() => {
  if (!props.modelValue) applyPreset(preset.value)
})
</script>

<template>
  <div class="date-range-picker">
    <BaseSelectButton :model-value="preset" :options="PRESETS" option-label="label" option-value="value" @update:model-value="onPresetChange" />
    <template v-if="preset === 'custom'">
      <BaseInputText v-model="customFrom" type="date" :aria-label="t('dateRangePicker.fromLabel')" @change="onCustomChange" />
      <span class="date-range-picker__sep" aria-hidden="true">–</span>
      <BaseInputText v-model="customTo" type="date" :aria-label="t('dateRangePicker.toLabel')" @change="onCustomChange" />
    </template>
    <span v-else class="date-range-picker__label">{{ rangeLabel }}</span>
  </div>
</template>

<style scoped>
.date-range-picker {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  flex-wrap: wrap;
}

.date-range-picker__label {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.date-range-picker__sep {
  color: var(--color-text-muted);
}
</style>
