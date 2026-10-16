<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import MetricCard from '@/components/base/MetricCard.vue'
import BaseChart from '@/components/base/BaseChart.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import type { TableColumn } from '@/components/base/BaseTable.vue'
import EntityLink from '@/components/EntityLink.vue'
import DiscountKindTable from '@/components/DiscountKindTable.vue'
import { useAuthStore } from '@/stores/auth'
import { useSharedDateRange } from '@/composables/useSharedDateRange'
import { useAsync } from '@/composables/useAsync'
import { getLoyaltyAnalytics, getActiveLoyaltyRedemptions } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatDate, formatCalendarDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const range = useSharedDateRange()

const { data: analytics, loading, error, reload } = useAsync(
  () => (range.value ? getLoyaltyAnalytics({ ...range.value, token: auth.token ?? undefined, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('loyaltyPoints.analyticsLoadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

watch(
  range,
  () => {
    if (range.value) reload()
  },
  { immediate: true },
)

const chartLabels = computed(() => (analytics.value?.series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [{ label: t('loyaltyPoints.chartSeriesLabel'), data: (analytics.value?.series || []).map((s) => s.value) }])
const hasChartData = computed(() => (analytics.value?.series || []).some((s) => s.value > 0))

const activeRedemptionsPage = ref(1)
const activeRedemptionsPerPage = ref(25)
const activeRedemptionsQuery = ref('')

const {
  data: activeRedemptionsData,
  loading: activeRedemptionsLoading,
  error: activeRedemptionsError,
  reload: reloadActiveRedemptions,
} = useAsync(() =>
  getActiveLoyaltyRedemptions({
    page: activeRedemptionsPage.value,
    perPage: activeRedemptionsPerPage.value,
    q: activeRedemptionsQuery.value || undefined,
    token: auth.token ?? undefined,
    projectId: auth.project?.id,
  })
)

watch(activeRedemptionsError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('loyaltyPoints.activeRedemptionsLoadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

const activeRedemptions = computed(() => activeRedemptionsData.value?.active_redemptions || [])
const activeRedemptionsMeta = computed(() => activeRedemptionsData.value?.meta)

function onActiveRedemptionsPage(event: { page: number; rows: number }) {
  activeRedemptionsPage.value = event.page
  activeRedemptionsPerPage.value = event.rows
  reloadActiveRedemptions()
}

function onActiveRedemptionsSearch(value: string) {
  activeRedemptionsQuery.value = value
  activeRedemptionsPage.value = 1
  reloadActiveRedemptions()
}

const activeRedemptionsColumns = computed<TableColumn[]>(() => [
  { field: 'customer', header: t('loyaltyPoints.customerColumn'), hideable: false, filter: { type: 'string', accessor: (row) => (row as { customer: { external_id: string } }).customer.external_id } },
  { field: 'quantity', header: t('loyaltyPoints.quantityColumn'), sortable: true, filter: { type: 'number' } },
  { field: 'expires_at', header: t('loyaltyPoints.expirationColumn'), sortable: true, filter: { type: 'date' } },
])

function viewCustomer(customer: { id: string }) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <DateRangePicker v-model="range" />
      </template>
    </PageHeader>

    <div class="metric-cards">
      <MetricCard
        :label="t('loyaltyPoints.totalQuantityMetric')"
        :value="analytics ? formatNumber(analytics.summary.total_redemption_quantity) : '—'"
        :trend="
          analytics
            ? {
                current: analytics.summary.total_redemption_quantity,
                previous: analytics.previous_period.total_redemption_quantity,
                caption: t('loyaltyPoints.previousPeriodCaption'),
              }
            : null
        "
      />
      <MetricCard
        :label="t('loyaltyPoints.totalPointsRedeemedMetric')"
        :value="analytics ? formatNumber(analytics.summary.total_points_redeemed) : '—'"
        :trend="
          analytics
            ? {
                current: analytics.summary.total_points_redeemed,
                previous: analytics.previous_period.total_points_redeemed,
                caption: t('loyaltyPoints.previousPeriodCaption'),
              }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('loyaltyPoints.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="(v: number) => formatNumber(v)" />
        <p v-else-if="!loading" class="empty-hint">{{ t('loyaltyPoints.noChartData') }}</p>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ t('loyaltyPoints.activeRedemptionsTitle') }}</template>
      <template #content>
        <BaseTable
          :data="activeRedemptions"
          :columns="activeRedemptionsColumns"
          :loading="activeRedemptionsLoading"
          row-key="id"
          lazy
          :total-records="activeRedemptionsMeta?.count ?? 0"
          :search-placeholder="t('loyaltyPoints.searchPlaceholder')"
          @refresh="reloadActiveRedemptions"
          @page="onActiveRedemptionsPage"
          @search="onActiveRedemptionsSearch"
        >
          <template #cell-customer="{ data }">
            <EntityLink @click="viewCustomer(data.customer)">{{ data.customer.external_id }}</EntityLink>
          </template>
          <template #cell-quantity="{ data }">{{ formatNumber(data.quantity) }}</template>
          <template #cell-expires_at="{ data }">{{ data.expires_at ? formatDate(data.expires_at, auth.project?.timezone) : '—' }}</template>
          <template #empty>{{ t('loyaltyPoints.noActiveRedemptions') }}</template>
        </BaseTable>
      </template>
    </BaseCard>

    <DiscountKindTable kind="loyalty" />
  </AppShell>
</template>

<style scoped>
.metric-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  margin: 0;
}
</style>
