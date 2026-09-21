<script setup>
import { computed, ref, watch } from 'vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useI18n } from 'vue-i18n'
import { AVAILABLE_LOCALES } from '@/i18n'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listUsers, createUser as createUserRequest } from '@/api/users'
import { userInputSchema } from '@/models/user'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast.js'

// A mountable section, not a route-level page — used inside
// ProjectSettingsView.vue's own BaseCard, which already supplies the
// AppShell/PageHeader/title this component used to own back when it was
// UsersView.vue's own standalone route.
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const { data: users, loading, error, reload } = useAsync(() => listUsers({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('users.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'id', header: t('users.idColumn'), sortable: true, hideable: false },
  { field: 'name', header: t('users.nameColumn'), sortable: true, filter: { type: 'string' } },
  { field: 'email', header: t('users.emailColumn'), sortable: true, filter: { type: 'string' } },
  {
    field: 'locale',
    header: t('users.localeColumn'),
    sortable: true,
    filter: { type: 'enum', options: AVAILABLE_LOCALES.map((l) => ({ label: l.label, value: l.code })) },
  },
])

const showCreate = ref(false)
const form = ref({ name: '', email: '' })
const errors = ref({})
const creating = ref(false)

function openCreate() {
  form.value = { name: '', email: '' }
  errors.value = {}
  showCreate.value = true
}

async function createUser() {
  errors.value = {}

  const result = userInputSchema(t).safeParse(form.value)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  creating.value = true
  try {
    await createUserRequest(result.data, { token: auth.token, projectId: auth.project?.id })
    showCreate.value = false
    form.value = { name: '', email: '' }
    toast.add({ severity: 'success', summary: t('users.createdSuccess'), life: 3000 })
    await reload()
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('users.genericError') }
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <div>
    <BaseTable
      :data="users || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('users.searchPlaceholder')"
      :create-label="$t('users.newUserButton')"
      @refresh="reload"
      @create="openCreate"
    >
      <template #cell-locale="{ data }">{{ AVAILABLE_LOCALES.find((l) => l.code === data.locale)?.label ?? data.locale }}</template>
    </BaseTable>

    <BaseDialog v-model:visible="showCreate" :header="$t('users.newUserDialogHeader')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="createUser">
        <label for="user-name">{{ $t('users.nameLabel') }}</label>
        <BaseInputText id="user-name" v-model="form.name" autofocus :invalid="!!errors.name" />
        <small v-if="errors.name" class="field-error">{{ errors.name }}</small>
        <label for="user-email">{{ $t('users.emailLabel') }}</label>
        <BaseInputText id="user-email" v-model="form.email" type="email" :invalid="!!errors.email" />
        <small v-if="errors.email" class="field-error">{{ errors.email }}</small>
        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('users.createButton')" :loading="creating" />
      </form>
    </BaseDialog>
  </div>
</template>

<style scoped>
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
