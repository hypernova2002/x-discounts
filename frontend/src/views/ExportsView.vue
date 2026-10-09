<script setup lang="ts">
import { computed, onMounted, onUnmounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import type { TableColumn } from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { useBaseToast } from '@/composables/useBaseToast'
import { listExports, exportDownloadPath } from '@/api/exports'
import { apiDownload } from '@/lib/api'
import { formatDateTime } from '@/lib/format'
import type { Export } from '@/models/export'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const { data: exports, loading, error, reload } = useAsync(() => listExports({ token: auth.token ?? undefined, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('exports.loadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

const STATUS_SEVERITY: Record<Export['status'], string> = { pending: 'secondary', processing: 'info', completed: 'success', failed: 'danger' }

// Keeps a row in progress updating live if the user is sitting on this page —
// cheap enough (and rare enough, in steady state nothing is pending/processing)
// not to need a push mechanism this app has no infrastructure for anyway.
const POLL_INTERVAL_MS = 3000
let pollTimer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  pollTimer = setInterval(() => {
    if ((exports.value ?? []).some((e) => e.status === 'pending' || e.status === 'processing')) reload()
  }, POLL_INTERVAL_MS)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

const columns = computed<TableColumn[]>(() => [
  { field: 'export_type', header: t('exports.typeColumn') },
  { field: 'status', header: t('exports.statusColumn') },
  { field: 'requested_by', header: t('exports.requestedByColumn') },
  { field: 'created_at', header: t('exports.createdAtColumn') },
  { field: 'byte_size', header: t('exports.sizeColumn') },
  { field: 'actions', header: t('exports.actionsColumn'), sortable: false, hideable: false },
])

function formatBytes(bytes: number | null): string {
  if (bytes == null) return '—'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

async function download(row: Export) {
  await apiDownload(exportDownloadPath(row.id), {
    token: auth.token ?? undefined,
    projectId: auth.project?.id,
    filename: row.filename ?? `${row.export_type}.csv`,
  })
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <BaseCard class="section-card">
      <template #content>
        <BaseTable :data="exports || []" :columns="columns" :loading="loading" row-key="id" @refresh="reload">
          <template #cell-export_type="{ data }">{{ t(`exports.types.${(data as unknown as Export).export_type}`) }}</template>
          <template #cell-status="{ data }">
            <BaseTag :severity="STATUS_SEVERITY[(data as unknown as Export).status]" :value="t(`exports.statuses.${(data as unknown as Export).status}`)" />
          </template>
          <template #cell-requested_by="{ data }">{{ (data as unknown as Export).requested_by ?? t('exports.unknownRequester') }}</template>
          <template #cell-created_at="{ data }">{{ formatDateTime((data as unknown as Export).created_at, auth.project?.timezone) }}</template>
          <template #cell-byte_size="{ data }">{{ formatBytes((data as unknown as Export).byte_size) }}</template>
          <template #cell-actions="{ data }">
            <BaseButton
              v-if="(data as unknown as Export).status === 'completed'"
              text
              icon="pi pi-download"
              :aria-label="t('exports.downloadButton')"
              @click="download(data as unknown as Export)"
            />
          </template>
        </BaseTable>
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
.section-card {
  margin-bottom: 1.5rem;
}
</style>
