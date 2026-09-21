<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import ProjectUsersSection from '@/components/ProjectUsersSection.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError, apiDownload } from '@/lib/api'
import { updateProject as updateProjectRequest } from '@/api/projects'
import { projectInputSchema } from '@/models/project'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'
import { TIMEZONE_OPTIONS } from '@/lib/timezone'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const form = ref({ name: auth.project?.name ?? '', timezone: auth.project?.timezone ?? '' })
const errors = ref({})
const saving = ref(false)

async function saveDetails() {
  errors.value = {}

  const result = projectInputSchema(t).safeParse(form.value)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  saving.value = true
  try {
    await updateProjectRequest(auth.project.id, result.data, { token: auth.token, projectId: auth.project?.id })
    // This page only ever edits the currently active project, so always
    // refresh the store snapshot — the topbar/timezone tag and every
    // formatDateTime call should reflect the change immediately.
    await auth.loadMe(auth.project.id)
    toast.add({ severity: 'success', summary: t('projects.updatedSuccess'), life: 3000 })
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('projects.genericError') }
  } finally {
    saving.value = false
  }
}

const exporting = ref(false)

async function exportProject() {
  exporting.value = true
  try {
    await apiDownload('/api/v1/admin/exports/project', { token: auth.token, projectId: auth.project?.id, filename: 'project-export.zip' })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('dashboard.exportError'), detail: e.message, life: 4000 })
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <BaseCard class="section-card">
      <template #title>{{ $t('projectSettings.detailsTitle') }}</template>
      <template #content>
        <form class="details-form" @submit.prevent="saveDetails">
          <div class="field">
            <label for="project-name">{{ $t('projects.nameLabel') }}</label>
            <BaseInputText id="project-name" v-model="form.name" :invalid="!!errors.name" />
            <small v-if="errors.name" class="field-error">{{ errors.name }}</small>
          </div>
          <div class="field">
            <label for="project-timezone">{{ $t('projects.timezoneLabel') }}</label>
            <BaseSelect id="project-timezone" v-model="form.timezone" :options="TIMEZONE_OPTIONS" option-label="label" option-value="value" filter />
            <small v-if="errors.timezone" class="field-error">{{ errors.timezone }}</small>
          </div>
          <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
          <div class="form-actions">
            <BaseButton type="submit" :label="$t('projects.saveButton')" :loading="saving" />
          </div>
        </form>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ $t('projectSettings.usersTitle') }}</template>
      <template #content>
        <ProjectUsersSection />
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ $t('dashboard.exportTitle') }}</template>
      <template #content>
        <p class="export-hint">{{ $t('dashboard.exportHint') }}</p>
        <BaseButton :label="$t('dashboard.exportButton')" :loading="exporting" @click="exportProject" />
      </template>
    </BaseCard>
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

.form-actions {
  display: flex;
  justify-content: flex-end;
}

.export-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}
</style>
