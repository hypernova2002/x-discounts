<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import EntityLink from '@/components/EntityLink.vue'
import OrderStatusTag from '@/components/OrderStatusTag.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import type { DateRange } from '@/components/DateRangePicker.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import type { TableColumn } from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import MetricCard from '@/components/base/MetricCard.vue'
import BaseChart from '@/components/base/BaseChart.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { useExportDownload } from '@/composables/useExportDownload'
import { listOrders } from '@/api/orders'
import { getOrderAnalytics } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatDateTime, formatCurrency, formatCalendarDate } from '@/lib/format'
import type { Order } from '@/models/order'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { exporting, runExport } = useExportDownload()
const range = ref<DateRange | null>(null)

const { data: orders, loading, error, reload } = useAsync(() => listOrders({ token: auth.token ?? undefined, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('orders.loadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

const { data: analytics, loading: analyticsLoading, error: analyticsError, reload: reloadAnalytics } = useAsync(
  () => (range.value ? getOrderAnalytics({ ...range.value, token: auth.token ?? undefined, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(analyticsError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('orders.analyticsLoadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

watch(range, () => {
  if (range.value) reloadAnalytics()
})

const chartLabels = computed(() => (analytics.value?.orders_series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [
  { label: t('orders.ordersSeriesLabel'), data: (analytics.value?.orders_series || []).map((s) => s.value), yAxisID: 'y' },
  { label: t('orders.revenueSeriesLabel'), data: (analytics.value?.revenue_series || []).map((s) => s.value), yAxisID: 'y1' },
])
const hasChartData = computed(
  () => (analytics.value?.orders_series || []).some((s) => s.value > 0) || (analytics.value?.revenue_series || []).some((s) => s.value > 0),
)

function formatTooltipValue(value: number, datasetLabel?: string): string {
  return datasetLabel === t('orders.revenueSeriesLabel') ? formatCurrency(value, auth.project?.currency) : formatNumber(value)
}

const columns = computed<TableColumn[]>(() => [
  { field: 'id', header: t('orders.order'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'customer', header: t('orders.customer'), hideable: false, filter: { type: 'string', accessor: (row) => (row as unknown as Order).customer.external_id } },
  { field: 'line_items', header: t('orders.items'), filter: { type: 'number', accessor: (row) => (row as unknown as Order).line_items.length } },
  { field: 'total_amount', header: t('orders.total'), sortable: true, filter: { type: 'number' } },
  { field: 'total_discount_amount', header: t('orders.discount'), sortable: true, filter: { type: 'number' } },
  {
    field: 'status',
    header: t('orders.statusColumn'),
    filter: {
      type: 'enum',
      options: ['active', 'cancelled', 'refunded', 'partially_refunded'].map((value) => ({ label: t(`orders.status.${value}`), value })),
    },
  },
  { field: 'created_at', header: t('orders.created'), sortable: true, filter: { type: 'date' } },
])

function createOrder() {
  router.push({ name: 'order-new' })
}

function viewOrder(order: Order) {
  router.push({ name: 'order-show', params: { id: order.id } })
}

function viewCustomer(customer: { id: string }) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}

async function exportOrders() {
  try {
    await runExport('orders')
  } catch (e) {
    toast.add({ severity: 'error', summary: t('orders.exportError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
  }
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <BaseButton icon="pi pi-plus" :label="t('orders.newOrder')" @click="createOrder" />
      </template>
      <template #actions>
        <DateRangePicker v-model="range" />
      </template>
    </PageHeader>

    <div class="metric-cards">
      <MetricCard
        :label="t('orders.totalOrdersMetric')"
        :value="analytics ? formatNumber(analytics.summary.total_orders) : '—'"
        :trend="
          analytics ? { current: analytics.summary.total_orders, previous: analytics.previous_period.total_orders, caption: t('orders.previousPeriodCaption') } : null
        "
      />
      <MetricCard
        :label="t('orders.totalRevenueMetric')"
        :value="analytics ? formatCurrency(analytics.summary.total_revenue, auth.project?.currency) : '—'"
        :trend="
          analytics ? { current: analytics.summary.total_revenue, previous: analytics.previous_period.total_revenue, caption: t('orders.previousPeriodCaption') } : null
        "
      />
      <MetricCard
        :label="t('orders.totalDiscountGivenMetric')"
        :value="analytics ? formatCurrency(analytics.summary.total_discount_given, auth.project?.currency) : '—'"
        :trend="
          analytics
            ? { current: analytics.summary.total_discount_given, previous: analytics.previous_period.total_discount_given, caption: t('orders.previousPeriodCaption') }
            : null
        "
      />
      <MetricCard :label="t('orders.averageOrderValueMetric')" :value="analytics ? formatCurrency(analytics.summary.average_order_value, auth.project?.currency) : '—'" />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('orders.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="formatTooltipValue" />
        <p v-else-if="!analyticsLoading" class="empty-hint">{{ t('orders.noChartData') }}</p>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #content>
        <BaseTable
          :data="orders || []"
          :columns="columns"
          :loading="loading"
          row-key="id"
          :search-placeholder="$t('orders.searchPlaceholder')"
          :export-label="$t('orders.exportButton')"
          :exporting="exporting"
          @row-click="viewOrder($event.data as unknown as Order)"
          @refresh="reload"
          @export="exportOrders"
        >
          <template #cell-customer="{ data }">
            <EntityLink @click="viewCustomer(data.customer)">{{ data.customer.external_id }}</EntityLink>
          </template>
          <template #cell-line_items="{ data }">{{ data.line_items.length }}</template>
          <template #cell-total_amount="{ data }">{{ formatCurrency(data.total_amount, auth.project?.currency) }}</template>
          <template #cell-total_discount_amount="{ data }">{{ formatCurrency(data.total_discount_amount, auth.project?.currency) }}</template>
          <template #cell-status="{ data }"><OrderStatusTag :status="data.status" /></template>
          <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at, auth.project?.timezone) }}</template>
        </BaseTable>
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
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
