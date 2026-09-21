<script setup>
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
import BaseTag from '@/components/base/BaseTag.vue'
import CountryFlag from '@/components/CountryFlag.vue'
import { useAuthStore } from '@/stores/auth'
import { apiDownload } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listCustomers } from '@/api/customers'
import { getCustomerAnalytics } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast.js'
import { formatDateTime, formatNumber, formatCurrency, formatCalendarDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { data: customers, loading, error, reload } = useAsync(() => listCustomers({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('customers.loadError'), detail: e.message, life: 4000 })
})

const exporting = ref(false)

const columns = computed(() => [
  { field: 'external_id', header: t('customers.externalId'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'name', header: t('customers.name'), sortable: true, filter: { type: 'string' } },
  { field: 'email', header: t('customers.email'), sortable: true, filter: { type: 'string' } },
  { field: 'membership', header: t('customers.membership') },
  { field: 'country', header: t('customers.country'), sortable: true, filter: { type: 'string' } },
  {
    field: 'marketing_opt_in',
    header: t('customers.marketingOptIn'),
    sortable: true,
    filter: {
      type: 'enum',
      options: [
        { label: t('customerDetail.details.yes'), value: true },
        { label: t('customerDetail.details.no'), value: false },
      ],
    },
  },
  { field: 'created_at', header: t('customers.created'), sortable: true, filter: { type: 'date' } },
])

function viewCustomer(customer) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}

async function exportCustomers() {
  exporting.value = true
  try {
    await apiDownload('/api/v1/admin/customers/export', { token: auth.token, projectId: auth.project?.id, filename: 'customers.csv' })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('customers.exportError'), detail: e.message, life: 4000 })
  } finally {
    exporting.value = false
  }
}

const range = ref(null)

const { data: analytics, loading: analyticsLoading, error: analyticsError, reload: reloadAnalytics } = useAsync(
  () => (range.value ? getCustomerAnalytics({ ...range.value, token: auth.token, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(analyticsError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('customers.analyticsLoadError'), detail: e.message, life: 4000 })
})

watch(range, () => {
  if (range.value) reloadAnalytics()
})

const chartLabels = computed(() => (analytics.value?.series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [{ label: t('customers.chartSeriesLabel'), data: (analytics.value?.series || []).map((s) => s.value) }])
const hasChartData = computed(() => (analytics.value?.series || []).some((s) => s.value > 0))
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <DateRangePicker v-model="range" />
      </template>
    </PageHeader>

    <div class="metric-cards">
      <MetricCard :label="t('customers.totalCustomersMetric')" :value="analytics ? formatNumber(analytics.summary.total_customers) : '—'" />
      <MetricCard :label="t('customers.activeCustomersMetric')" :value="analytics ? formatNumber(analytics.summary.active_customers) : '—'" />
      <MetricCard :label="t('customers.totalSpentMetric')" :value="analytics ? formatCurrency(analytics.summary.total_spent) : '—'" />
      <MetricCard
        :label="t('customers.newCustomersMetric')"
        :value="analytics ? formatNumber(analytics.summary.new_customers) : '—'"
        :trend="
          analytics
            ? { current: analytics.summary.new_customers, previous: analytics.previous_period.new_customers, caption: t('customers.previousPeriodCaption') }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('customers.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="(v) => formatNumber(v)" />
        <p v-else-if="!analyticsLoading" class="empty-hint">{{ t('customers.noChartData') }}</p>
      </template>
    </BaseCard>

    <BaseTable
      :data="customers || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('customers.searchPlaceholder')"
      :export-label="$t('customers.exportButton')"
      :exporting="exporting"
      @row-click="viewCustomer($event.data)"
      @refresh="reload"
      @export="exportCustomers"
    >
      <template #cell-membership="{ data }">
        <BaseTag v-if="data.membership_tier" severity="success" :value="`${data.membership_tier.membership_scheme.name} — ${data.membership_tier.name}`" />
        <span v-else class="no-membership">{{ $t('customers.noMembership') }}</span>
      </template>
      <template #cell-country="{ data }"><CountryFlag :code="data.country" /></template>
      <template #cell-marketing_opt_in="{ data }">{{ data.marketing_opt_in ? $t('customerDetail.details.yes') : $t('customerDetail.details.no') }}</template>
      <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at, auth.project?.timezone) }}</template>
    </BaseTable>
  </AppShell>
</template>

<style scoped>
.no-membership {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

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
