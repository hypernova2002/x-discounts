<script setup>
import { computed, ref, watch } from 'vue'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listProjects, createProject as createProjectRequest } from '@/api/projects'
import { projectInputSchema } from '@/models/project'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast.js'
import { formatDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const { data: projects, loading, error, reload } = useAsync(() => listProjects({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('projects.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'id', header: t('projects.idColumn'), sortable: true, hideable: false },
  { field: 'name', header: t('projects.nameColumn'), sortable: true },
  { field: 'created_at', header: t('projects.createdColumn'), sortable: true },
])

const showCreate = ref(false)
const newName = ref('')
const errors = ref({})
const creating = ref(false)

function openCreate() {
  newName.value = ''
  errors.value = {}
  showCreate.value = true
}

async function createProject() {
  errors.value = {}

  const result = projectInputSchema(t).safeParse({ name: newName.value })
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  creating.value = true
  try {
    await createProjectRequest(result.data, { token: auth.token, projectId: auth.project?.id })
    showCreate.value = false
    newName.value = ''
    toast.add({ severity: 'success', summary: t('projects.createdSuccess'), life: 3000 })
    await reload()
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('projects.genericError') }
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <BaseButton :label="$t('projects.newProjectButton')" @click="openCreate" />
      </template>
    </PageHeader>

    <BaseTable :data="projects || []" :columns="columns" :loading="loading" row-key="id" :search-placeholder="$t('projects.searchPlaceholder')" @refresh="reload">
      <template #cell-created_at="{ data }">{{ formatDate(data.created_at) }}</template>
    </BaseTable>

    <BaseDialog v-model:visible="showCreate" :header="$t('projects.newProjectDialogHeader')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="createProject">
        <label for="project-name">{{ $t('projects.nameLabel') }}</label>
        <BaseInputText id="project-name" v-model="newName" autofocus :invalid="!!errors.name" />
        <small v-if="errors.name" class="field-error">{{ errors.name }}</small>
        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('projects.createButton')" :loading="creating" />
      </form>
    </BaseDialog>
  </AppShell>
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
