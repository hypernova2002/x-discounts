<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import AppShell from '@/components/AppShell.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import { apiDownload } from '@/lib/api'
import { useBaseToast } from '@/composables/useBaseToast'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()
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
    <h1>{{ auth.user ? $t('dashboard.welcomeBackName', { name: auth.user.name }) : $t('dashboard.welcomeBack') }}</h1>
    <BaseCard>
      <template #title>{{ $t('dashboard.signedInAs') }}</template>
      <template #content>
        <dl class="details">
          <dt>{{ $t('dashboard.projectLabel') }}</dt>
          <dd>{{ auth.project?.name }}</dd>
          <dt>{{ $t('dashboard.userLabel') }}</dt>
          <dd>{{ auth.user?.email }}</dd>
          <dt>{{ $t('dashboard.roleLabel') }}</dt>
          <dd>{{ auth.role }}</dd>
        </dl>
      </template>
    </BaseCard>
    <BaseCard class="export-card">
      <template #title>{{ $t('dashboard.exportTitle') }}</template>
      <template #content>
        <p class="export-hint">{{ $t('dashboard.exportHint') }}</p>
        <BaseButton :label="$t('dashboard.exportButton')" :loading="exporting" @click="exportProject" />
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
.export-card {
  margin-top: 1rem;
}

.export-hint {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}
</style>
