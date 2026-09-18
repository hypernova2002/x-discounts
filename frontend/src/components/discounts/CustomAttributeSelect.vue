<script setup>
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { apiFetch, ApiError } from '@/lib/api'
import { useBaseToast } from '@/composables/useBaseToast'
import { useCustomAttributes } from '@/composables/useCustomAttributes'
import { reservedKeysFor } from '@/lib/reservedConditionKeys'

defineOptions({ name: 'CustomAttributeSelect' })

const { t } = useI18n()

const DATA_TYPE_OPTIONS = computed(() => [
  { label: t('customAttributeSelect.dataTypes.string'), value: 'string' },
  { label: t('customAttributeSelect.dataTypes.number'), value: 'number' },
  { label: t('customAttributeSelect.dataTypes.boolean'), value: 'boolean' },
  { label: t('customAttributeSelect.dataTypes.date'), value: 'date' },
])
const ENTITY_LABEL_KEYS = { cart: 'cart', line_item: 'lineItem', customer: 'customer' }

function entityLabel(entity) {
  const key = ENTITY_LABEL_KEYS[entity]
  return key ? t(`customAttributeSelect.entities.${key}`) : entity
}

const props = defineProps({
  modelValue: { type: String, default: null },
  entity: { type: String, required: true },
})
// 'select' carries the full attribute record (including data_type) for callers that
// need more than just the key — update:modelValue alone only ever carries the key string.
const emit = defineEmits(['update:modelValue', 'select'])

const auth = useAuthStore()
const toast = useBaseToast()
const { load, attributesFor, invalidate } = useCustomAttributes()

watch(
  () => props.entity,
  (entity) => {
    if (entity) load(entity, { token: auth.token, projectId: auth.project?.id })
  },
  { immediate: true }
)

const attributes = computed(() => attributesFor(props.entity))
const reservedAttributes = computed(() => reservedKeysFor(props.entity))
const options = computed(() => [
  ...reservedAttributes.value.map((r) => ({ label: t('customAttributeSelect.builtinOptionLabel', { key: r.key }), value: r.key })),
  ...attributes.value.map((a) => ({ label: a.key, value: a.key })),
])

function onSelect(key) {
  emit('update:modelValue', key)
  emit(
    'select',
    reservedAttributes.value.find((r) => r.key === key) || attributes.value.find((a) => a.key === key)
  )
}

const showCreate = ref(false)
const newKey = ref('')
const newDataType = ref('string')
const creating = ref(false)
const createError = ref('')

function openCreate() {
  newKey.value = ''
  newDataType.value = 'string'
  createError.value = ''
  showCreate.value = true
}

async function createAttribute() {
  creating.value = true
  createError.value = ''
  try {
    await apiFetch('/api/v1/admin/custom_attributes', {
      method: 'POST',
      token: auth.token,
      projectId: auth.project?.id,
      body: { entity: props.entity, key: newKey.value, data_type: newDataType.value },
    })
    invalidate()
    await load(props.entity, { token: auth.token, projectId: auth.project?.id })
    onSelect(newKey.value)
    showCreate.value = false
    toast.add({ severity: 'success', summary: t('customAttributeSelect.createdToast'), life: 3000 })
  } catch (e) {
    createError.value = e instanceof ApiError ? e.message : t('customAttributeSelect.genericError')
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <BaseSelect
    :model-value="modelValue"
    :options="options"
    option-label="label"
    option-value="value"
    :placeholder="t('customAttributeSelect.placeholder')"
    filter
    :filter-placeholder="t('customAttributeSelect.filterPlaceholder')"
    @update:model-value="onSelect"
  >
    <template #footer>
      <div class="custom-attribute-select-footer">
        <BaseButton text size="small" :label="t('customAttributeSelect.newAttributeButton')" @click="openCreate" />
      </div>
    </template>
  </BaseSelect>

  <BaseDialog v-model:visible="showCreate" :header="t('customAttributeSelect.newAttributeHeader', { entity: entityLabel(entity) })" modal :style="{ width: '22rem' }">
    <form class="attr-create-form" @submit.prevent="createAttribute">
      <label>{{ $t('customAttributeSelect.keyLabel') }}</label>
      <BaseInputText v-model="newKey" autofocus required />
      <label>{{ $t('customAttributeSelect.dataTypeLabel') }}</label>
      <BaseSelect v-model="newDataType" :options="DATA_TYPE_OPTIONS" option-label="label" option-value="value" />
      <BaseMessage v-if="createError" severity="error" :closable="false">{{ createError }}</BaseMessage>
      <BaseButton type="submit" :label="t('customAttributeSelect.createButton')" :loading="creating" />
    </form>
  </BaseDialog>
</template>

<style scoped>
.custom-attribute-select-footer {
  padding: 0.5rem;
  border-top: 1px solid var(--color-border);
}

.attr-create-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
