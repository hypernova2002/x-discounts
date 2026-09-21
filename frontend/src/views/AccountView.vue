<script setup>
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { getAccount, updateAccount } from '@/api/account'
import { accountInputSchema } from '@/models/account'
import { listProjects, createProject as createProjectRequest } from '@/api/projects'
import { projectInputSchema } from '@/models/project'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatDate } from '@/lib/format'
import { TIMEZONE_OPTIONS } from '@/lib/timezone'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const { data: account, loading: accountLoading, error: accountError } = useAsync(() =>
  getAccount({ token: auth.token, projectId: auth.project?.id }),
)

watch(accountError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('account.loadError'), detail: e.message, life: 4000 })
})

const accountForm = ref({ name: '' })
const otpRequired = ref(false)
watch(
  account,
  (a) => {
    if (a) {
      accountForm.value = { name: a.name }
      otpRequired.value = a.otp_required
    }
  },
  { immediate: true },
)

const accountErrors = ref({})
const savingAccount = ref(false)

async function saveAccount() {
  accountErrors.value = {}

  const result = accountInputSchema(t).safeParse(accountForm.value)
  if (!result.success) {
    accountErrors.value = toFieldErrors(result.error)
    return
  }

  savingAccount.value = true
  try {
    await updateAccount({ ...result.data, otp_required: otpRequired.value }, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('account.updatedSuccess'), life: 3000 })
  } catch (e) {
    accountErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('account.genericError') }
  } finally {
    savingAccount.value = false
  }
}

const { data: projects, loading: projectsLoading, error: projectsError, reload: reloadProjects } = useAsync(() =>
  listProjects({ token: auth.token, projectId: auth.project?.id }),
)

watch(projectsError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('projects.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'id', header: t('projects.idColumn'), sortable: true, hideable: false },
  { field: 'name', header: t('projects.nameColumn'), sortable: true, filter: { type: 'string' } },
  { field: 'timezone', header: t('projects.timezoneColumn'), sortable: true, filter: { type: 'string' } },
  { field: 'created_at', header: t('projects.createdColumn'), sortable: true, filter: { type: 'date' } },
])

const switchingProject = ref(false)

async function selectProject(project) {
  if (project.id === auth.project?.id) return
  switchingProject.value = true
  try {
    await auth.selectProject(project.id)
  } catch (e) {
    toast.add({ severity: 'error', summary: t('nav.switchProjectError'), detail: e.message, life: 4000 })
  } finally {
    switchingProject.value = false
  }
}

const dialogOpen = ref(false)
const projectForm = ref({ name: '', timezone: '' })
const projectErrors = ref({})
const creatingProject = ref(false)

function openCreate() {
  projectForm.value = { name: '', timezone: Intl.DateTimeFormat().resolvedOptions().timeZone }
  projectErrors.value = {}
  dialogOpen.value = true
}

async function submitProject() {
  projectErrors.value = {}

  const result = projectInputSchema(t).safeParse(projectForm.value)
  if (!result.success) {
    projectErrors.value = toFieldErrors(result.error)
    return
  }

  creatingProject.value = true
  try {
    await createProjectRequest(result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('projects.createdSuccess'), life: 3000 })
    dialogOpen.value = false
    await reloadProjects()
  } catch (e) {
    projectErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('projects.genericError') }
  } finally {
    creatingProject.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <BaseCard class="section-card">
      <template #title>{{ $t('account.detailsTitle') }}</template>
      <template #content>
        <form class="details-form" @submit.prevent="saveAccount">
          <div class="field">
            <label for="account-name">{{ $t('account.nameLabel') }}</label>
            <BaseInputText id="account-name" v-model="accountForm.name" :invalid="!!accountErrors.name" :disabled="accountLoading" />
            <small v-if="accountErrors.name" class="field-error">{{ accountErrors.name }}</small>
          </div>
          <div class="toggle-field">
            <BaseToggleSwitch id="account-otp-required" v-model="otpRequired" />
            <label for="account-otp-required">{{ $t('account.otpRequiredLabel') }}</label>
          </div>
          <p class="toggle-hint">{{ $t('account.otpRequiredHint') }}</p>
          <BaseMessage v-if="accountErrors._root" severity="error" :closable="false">{{ accountErrors._root }}</BaseMessage>
          <div class="form-actions">
            <BaseButton type="submit" :label="$t('account.saveButton')" :loading="savingAccount" />
          </div>
        </form>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ $t('projects.title') }}</template>
      <template #content>
        <BaseTable
          :data="projects || []"
          :columns="columns"
          :loading="projectsLoading || switchingProject"
          row-key="id"
          :search-placeholder="$t('projects.searchPlaceholder')"
          :create-label="$t('projects.newProjectButton')"
          @refresh="reloadProjects"
          @create="openCreate"
          @row-click="selectProject($event.data)"
        >
          <template #cell-created_at="{ data }">{{ formatDate(data.created_at, auth.project?.timezone) }}</template>
        </BaseTable>
      </template>
    </BaseCard>

    <BaseDialog v-model:visible="dialogOpen" :header="$t('projects.newProjectDialogHeader')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="submitProject">
        <label for="new-project-name">{{ $t('projects.nameLabel') }}</label>
        <BaseInputText id="new-project-name" v-model="projectForm.name" autofocus :invalid="!!projectErrors.name" />
        <small v-if="projectErrors.name" class="field-error">{{ projectErrors.name }}</small>
        <label for="new-project-timezone">{{ $t('projects.timezoneLabel') }}</label>
        <BaseSelect id="new-project-timezone" v-model="projectForm.timezone" :options="TIMEZONE_OPTIONS" option-label="label" option-value="value" filter />
        <small v-if="projectErrors.timezone" class="field-error">{{ projectErrors.timezone }}</small>
        <BaseMessage v-if="projectErrors._root" severity="error" :closable="false">{{ projectErrors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('projects.createButton')" :loading="creatingProject" />
      </form>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.details-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-width: 24rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.field label {
  font-size: 0.875rem;
  font-weight: 600;
}

.field-error {
  color: var(--color-danger);
  font-size: 0.8125rem;
}

.toggle-field {
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

.toggle-field label {
  font-size: 0.875rem;
  font-weight: 600;
}

.toggle-hint {
  margin: -0.5rem 0 0;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
}

.create-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
