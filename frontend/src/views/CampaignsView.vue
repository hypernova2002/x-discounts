<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import CampaignStatusTags from '@/components/CampaignStatusTags.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listCampaigns, exportCampaigns as exportCampaignsRequest } from '@/api/campaigns'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatDateTime } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const showArchived = ref(false)
const exporting = ref(false)

const { data: campaigns, loading, error, reload } = useAsync(() =>
  listCampaigns({ includeArchived: showArchived.value, token: auth.token, projectId: auth.project?.id })
)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('campaigns.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'name', header: t('campaigns.nameColumn'), sortable: true, hideable: false, filter: { type: 'string' } },
  {
    field: 'enabled',
    header: t('campaigns.statusColumn'),
    filter: {
      type: 'enum',
      options: [
        { label: t('campaigns.statusEnabled'), value: true },
        { label: t('campaignStatusTags.paused'), value: false },
      ],
    },
  },
  { field: 'valid_from', header: t('campaigns.validFromColumn'), sortable: true, filter: { type: 'date' } },
  { field: 'valid_until', header: t('campaigns.validUntilColumn'), sortable: true, filter: { type: 'date' } },
  {
    field: 'archived',
    header: t('campaigns.archivedColumn'),
    filter: {
      type: 'enum',
      options: [
        { label: t('campaignStatusTags.archived'), value: true },
        { label: t('campaigns.notArchived'), value: false },
      ],
    },
  },
  { field: 'actions', header: t('campaigns.actionsColumn'), hideable: false },
])

function createCampaign() {
  router.push({ name: 'campaign-new' })
}

function viewCampaign(campaign) {
  router.push({ name: 'campaign-show', params: { id: campaign.id } })
}

function editCampaign(campaign) {
  router.push({ name: 'campaign-edit', params: { id: campaign.id } })
}

function onShowArchivedChange() {
  reload()
}

async function exportCampaigns() {
  exporting.value = true
  try {
    await exportCampaignsRequest({ includeArchived: showArchived.value, token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('campaigns.exportError'), detail: e.message, life: 4000 })
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <label class="flex items-center gap-2 text-sm text-text-muted">
          <BaseToggleSwitch v-model="showArchived" @update:model-value="onShowArchivedChange" />
          {{ $t('campaigns.showArchivedLabel') }}
        </label>
      </template>
    </PageHeader>

    <BaseTable
      :data="campaigns || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('campaigns.searchPlaceholder')"
      :create-label="$t('campaigns.newCampaign')"
      :export-label="$t('campaigns.exportButton')"
      :exporting="exporting"
      @row-click="viewCampaign($event.data)"
      @refresh="reload"
      @create="createCampaign"
      @export="exportCampaigns"
    >
      <template #cell-enabled="{ data }">
        <CampaignStatusTags :campaign="data" />
      </template>
      <template #cell-valid_from="{ data }">{{ data.valid_from ? formatDateTime(data.valid_from, auth.project?.timezone) : '—' }}</template>
      <template #cell-valid_until="{ data }">{{ data.valid_until ? formatDateTime(data.valid_until, auth.project?.timezone) : '—' }}</template>
      <template #cell-archived="{ data }">{{ data.archived ? $t('campaignStatusTags.archived') : $t('campaigns.notArchived') }}</template>
      <template #cell-actions="{ data }">
        <BaseButton text icon="pi pi-pencil" :aria-label="$t('campaigns.editButton')" @click.stop="editCampaign(data)" />
      </template>
    </BaseTable>
  </AppShell>
</template>
