<script setup>
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listCustomAttributes, createCustomAttribute, deleteCustomAttribute as deleteCustomAttributeRequest } from '@/api/customAttributes'
import { customAttributeInputSchema } from '@/models/customAttribute'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast.js'
import { useCustomAttributes } from '@/composables/useCustomAttributes'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()
const { invalidate } = useCustomAttributes()

const ENTITY_OPTIONS = computed(() => [
  { label: t('customAttributes.entityOptions.cart'), value: 'cart' },
  { label: t('customAttributes.entityOptions.lineItem'), value: 'line_item' },
  { label: t('customAttributes.entityOptions.customer'), value: 'customer' },
])
const DATA_TYPE_OPTIONS = computed(() => [
  { label: t('customAttributes.dataTypeOptions.string'), value: 'string' },
  { label: t('customAttributes.dataTypeOptions.number'), value: 'number' },
  { label: t('customAttributes.dataTypeOptions.boolean'), value: 'boolean' },
  { label: t('customAttributes.dataTypeOptions.date'), value: 'date' },
])

const entityFilter = ref(null)

const {
  data: attributes,
  loading,
  error,
  reload,
} = useAsync(() => listCustomAttributes({ entity: entityFilter.value, token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('customAttributes.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'entity', header: t('customAttributes.columns.entity'), hideable: false },
  { field: 'key', header: t('customAttributes.columns.key'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'data_type', header: t('customAttributes.columns.type'), sortable: true, filter: { type: 'enum', options: DATA_TYPE_OPTIONS.value } },
  { field: 'actions', header: t('customAttributes.columns.actions'), hideable: false },
])

const showCreate = ref(false)
const form = ref({ entity: 'cart', key: '', data_type: 'string' })
const errors = ref({})
const creating = ref(false)

function openCreate() {
  form.value = { entity: 'cart', key: '', data_type: 'string' }
  errors.value = {}
  showCreate.value = true
}

async function createAttribute() {
  errors.value = {}

  const result = customAttributeInputSchema(t).safeParse(form.value)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  creating.value = true
  try {
    await createCustomAttribute(result.data, { token: auth.token, projectId: auth.project?.id })
    showCreate.value = false
    form.value = { entity: 'cart', key: '', data_type: 'string' }
    toast.add({ severity: 'success', summary: t('customAttributes.attributeCreated'), life: 3000 })
    invalidate()
    await reload()
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('customAttributes.genericError') }
  } finally {
    creating.value = false
  }
}

async function deleteAttribute(attribute) {
  if (!confirm(t('customAttributes.deleteConfirm', { key: attribute.key }))) return
  try {
    await deleteCustomAttributeRequest(attribute.id, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('customAttributes.attributeDeleted'), life: 3000 })
    invalidate()
    await reload()
  } catch (e) {
    toast.add({ severity: 'error', summary: t('customAttributes.deleteError'), detail: e.message, life: 4000 })
  }
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <div class="filter-row">
      <BaseSelect
        v-model="entityFilter"
        :options="ENTITY_OPTIONS"
        option-label="label"
        option-value="value"
        :placeholder="$t('customAttributes.allEntitiesPlaceholder')"
        show-clear
        @update:model-value="reload"
      />
    </div>

    <BaseTable
      :data="attributes || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('customAttributes.searchPlaceholder')"
      :create-label="$t('customAttributes.newAttributeButton')"
      @refresh="reload"
      @create="openCreate"
    >
      <template #cell-entity="{ data }"><BaseTag :value="data.entity" /></template>
      <template #cell-actions="{ data }">
        <BaseButton text severity="danger" :label="$t('customAttributes.deleteButton')" @click="deleteAttribute(data)" />
      </template>
    </BaseTable>

    <BaseDialog v-model:visible="showCreate" :header="$t('customAttributes.newAttributeDialogTitle')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="createAttribute">
        <label for="attr-entity">{{ $t('customAttributes.entityLabel') }}</label>
        <BaseSelect id="attr-entity" v-model="form.entity" :options="ENTITY_OPTIONS" option-label="label" option-value="value" />
        <label for="attr-key">{{ $t('customAttributes.keyLabel') }}</label>
        <BaseInputText id="attr-key" v-model="form.key" autofocus :invalid="!!errors.key" />
        <small v-if="errors.key" class="field-error">{{ errors.key }}</small>
        <label for="attr-type">{{ $t('customAttributes.dataTypeLabel') }}</label>
        <BaseSelect id="attr-type" v-model="form.data_type" :options="DATA_TYPE_OPTIONS" option-label="label" option-value="value" />
        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('customAttributes.createButton')" :loading="creating" />
      </form>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.filter-row {
  margin-bottom: 1rem;
  display: flex;
  gap: 0.75rem;
}

.create-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field-error {
  color: var(--p-red-500, #ef4444);
  font-size: 0.8125rem;
}
</style>
