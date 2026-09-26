<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { computed } from 'vue'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import LifecycleStatus from '@/components/LifecycleStatus.vue'
import DiscountKindTag from '@/components/DiscountKindTag.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import MetricCard from '@/components/base/MetricCard.vue'
import BaseChart from '@/components/base/BaseChart.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listCampaigns, exportCampaigns as exportCampaignsRequest } from '@/api/campaigns'
import { getCampaignAnalytics } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatMonthDayYear, formatNumber, formatCurrency, formatCalendarDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const showArchived = ref(false)
const exporting = ref(false)
const range = ref(null)

const { data: campaigns, loading, error, reload } = useAsync(() =>
  listCampaigns({ includeArchived: showArchived.value, token: auth.token, projectId: auth.project?.id })
)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('campaigns.loadError'), detail: e.message, life: 4000 })
})

const { data: analytics, loading: analyticsLoading, error: analyticsError, reload: reloadAnalytics } = useAsync(
  () => (range.value ? getCampaignAnalytics({ ...range.value, token: auth.token, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(analyticsError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('campaigns.analyticsLoadError'), detail: e.message, life: 4000 })
})

watch(range, () => {
  if (range.value) reloadAnalytics()
})

const chartLabels = computed(() => (analytics.value?.usage_series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [
  { label: t('campaigns.redemptionsSeriesLabel'), data: (analytics.value?.usage_series || []).map((s) => s.value), yAxisID: 'y' },
  { label: t('campaigns.discountedSeriesLabel'), data: (analytics.value?.earnings_series || []).map((s) => s.value), yAxisID: 'y1' },
])
const hasChartData = computed(
  () => (analytics.value?.usage_series || []).some((s) => s.value > 0) || (analytics.value?.earnings_series || []).some((s) => s.value > 0),
)

function formatTooltipValue(value, datasetLabel) {
  return datasetLabel === t('campaigns.discountedSeriesLabel') ? formatCurrency(value) : formatNumber(value)
}

const columns = computed(() => [
  { field: 'name', header: t('campaigns.nameColumn'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'discount_kinds', header: t('campaigns.discountTypesColumn') },
  { field: 'valid_from', header: t('campaigns.validFromColumn'), sortable: true, filter: { type: 'date' } },
  { field: 'valid_until', header: t('campaigns.validUntilColumn'), sortable: true, filter: { type: 'date' } },
  { field: 'status', header: t('campaigns.statusColumn'), hideable: false },
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
      <template #title>
        <BaseButton icon="pi pi-plus" :label="t('campaigns.newCampaign')" @click="createCampaign" />
      </template>
      <template #actions>
        <DateRangePicker v-model="range" />
        <label class="flex items-center gap-2 text-sm text-text-muted">
          <BaseToggleSwitch v-model="showArchived" @update:model-value="onShowArchivedChange" />
          {{ $t('campaigns.showArchivedLabel') }}
        </label>
      </template>
    </PageHeader>

    <div class="metric-cards">
      <MetricCard :label="t('campaigns.totalCampaignsMetric')" :value="analytics ? formatNumber(analytics.summary.total_campaigns) : '—'" />
      <MetricCard :label="t('campaigns.activeCampaignsMetric')" :value="analytics ? formatNumber(analytics.summary.active_campaigns) : '—'" />
      <MetricCard
        :label="t('campaigns.totalRedemptionsMetric')"
        :value="analytics ? formatNumber(analytics.summary.total_redemptions) : '—'"
        :trend="
          analytics
            ? { current: analytics.summary.total_redemptions, previous: analytics.previous_period.total_redemptions, caption: t('campaigns.previousPeriodCaption') }
            : null
        "
      />
      <MetricCard
        :label="t('campaigns.totalDiscountedMetric')"
        :value="analytics ? formatCurrency(analytics.summary.total_discounted_amount) : '—'"
        :trend="
          analytics
            ? {
                current: analytics.summary.total_discounted_amount,
                previous: analytics.previous_period.total_discounted_amount,
                caption: t('campaigns.previousPeriodCaption'),
              }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('campaigns.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="formatTooltipValue" />
        <p v-else-if="!analyticsLoading" class="empty-hint">{{ t('campaigns.noChartData') }}</p>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #content>
        <BaseTable
          :data="campaigns || []"
          :columns="columns"
          :loading="loading"
          row-key="id"
          :search-placeholder="$t('campaigns.searchPlaceholder')"
          :export-label="$t('campaigns.exportButton')"
          :exporting="exporting"
          @row-click="viewCampaign($event.data)"
          @refresh="reload"
          @export="exportCampaigns"
        >
          <template #cell-discount_kinds="{ data }">
            <span class="discount-kinds">
              <DiscountKindTag v-for="kind in data.discount_kinds" :key="kind" :kind="kind" />
            </span>
          </template>
          <template #cell-valid_from="{ data }">{{ data.valid_from ? formatMonthDayYear(data.valid_from, auth.project?.timezone) : '—' }}</template>
          <template #cell-valid_until="{ data }">{{ data.valid_until ? formatMonthDayYear(data.valid_until, auth.project?.timezone) : '—' }}</template>
          <template #cell-status="{ data }">
            <LifecycleStatus compact :enabled="data.enabled" :archived="data.archived" :from="data.valid_from" :until="data.valid_until" />
          </template>
          <template #cell-actions="{ data }">
            <BaseButton text icon="pi pi-pencil" :aria-label="$t('campaigns.editButton')" @click.stop="editCampaign(data)" />
          </template>
        </BaseTable>
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
.discount-kinds {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 0.375rem;
}

.metric-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.section-card {
  margin-bottom: 1.5rem;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  margin: 0;
}
</style>
