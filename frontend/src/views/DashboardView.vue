<script setup>
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { useBaseToast } from '@/composables/useBaseToast'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import DiscountKindTag from '@/components/DiscountKindTag.vue'
import OrderStatusTag from '@/components/OrderStatusTag.vue'
import EntityLink from '@/components/EntityLink.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import MetricCard from '@/components/base/MetricCard.vue'
import BaseChart from '@/components/base/BaseChart.vue'
import { getOrderAnalytics, getCustomerAnalytics, getCampaignAnalytics, getAttentionItems } from '@/api/analytics'
import { listOrders } from '@/api/orders'
import { formatNumber, formatCurrency, formatCalendarDate, formatMonthDayYear, formatDateTime } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const range = ref(null)

// One combined fetch — the KPI row and chart are all one screen's worth of
// data pulled from three already-built per-domain analytics endpoints
// (orders/customers/campaigns), rather than three separately-loading widgets.
const { data: overview, loading: overviewLoading, error: overviewError, reload: reloadOverview } = useAsync(async () => {
  if (!range.value) return null
  const params = { ...range.value, token: auth.token, projectId: auth.project?.id }
  const [orders, customers, campaigns] = await Promise.all([getOrderAnalytics(params), getCustomerAnalytics(params), getCampaignAnalytics(params)])
  return { orders, customers, campaigns }
}, { immediate: false })

watch(overviewError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('dashboard.overviewLoadError'), detail: e.message, life: 4000 })
})

watch(range, () => {
  if (range.value) reloadOverview()
})

const chartLabels = computed(() => (overview.value?.orders.orders_series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [
  { label: t('dashboard.ordersSeriesLabel'), data: (overview.value?.orders.orders_series || []).map((s) => s.value), yAxisID: 'y' },
  { label: t('dashboard.revenueSeriesLabel'), data: (overview.value?.orders.revenue_series || []).map((s) => s.value), yAxisID: 'y1' },
])
const hasChartData = computed(
  () => (overview.value?.orders.orders_series || []).some((s) => s.value > 0) || (overview.value?.orders.revenue_series || []).some((s) => s.value > 0),
)

function formatTooltipValue(value, datasetLabel) {
  return datasetLabel === t('dashboard.revenueSeriesLabel') ? formatCurrency(value) : formatNumber(value)
}

const { data: attention, loading: attentionLoading, error: attentionError } = useAsync(() =>
  getAttentionItems({ token: auth.token, projectId: auth.project?.id }),
)

watch(attentionError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('dashboard.attentionLoadError'), detail: e.message, life: 4000 })
})

const attentionItems = computed(() => {
  if (!attention.value) return []
  const campaigns = attention.value.campaigns.map((c) => ({ type: 'campaign', id: c.id, name: c.name, until: c.until }))
  const discounts = attention.value.discounts.map((d) => ({ type: 'discount', id: d.id, name: d.name, kind: d.kind, until: d.until }))
  return [...campaigns, ...discounts].sort((a, b) => new Date(a.until) - new Date(b.until))
})

function daysUntil(iso) {
  const ms = new Date(iso) - new Date()
  return Math.max(0, Math.ceil(ms / (24 * 60 * 60 * 1000)))
}

function endsInLabel(iso) {
  const days = daysUntil(iso)
  return days === 0 ? t('lifecycleStatus.endsToday') : t('lifecycleStatus.endsInDays', { days })
}

function viewAttentionItem(item) {
  if (item.type === 'campaign') router.push({ name: 'campaign-show', params: { id: item.id } })
  else router.push({ name: 'discount-show', params: { id: item.id } })
}

const { data: recentOrders, loading: recentOrdersLoading, error: recentOrdersError } = useAsync(() =>
  listOrders({ perPage: 5, token: auth.token, projectId: auth.project?.id }),
)

watch(recentOrdersError, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('dashboard.recentOrdersLoadError'), detail: e.message, life: 4000 })
})

const recentOrdersColumns = computed(() => [
  { field: 'id', header: t('orders.order'), hideable: false },
  { field: 'customer', header: t('orders.customer'), hideable: false },
  { field: 'total_amount', header: t('orders.total'), hideable: false },
  { field: 'status', header: t('orders.statusColumn'), hideable: false },
  { field: 'created_at', header: t('orders.created'), hideable: false },
])

function viewOrder(order) {
  router.push({ name: 'order-show', params: { id: order.id } })
}

function viewCustomer(customer) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}

function viewAllOrders() {
  router.push({ name: 'orders' })
}
</script>

<template>
  <AppShell>
    <h1>{{ auth.user ? $t('dashboard.welcomeBackName', { name: auth.user.name }) : $t('dashboard.welcomeBack') }}</h1>

    <PageHeader>
      <template #actions>
        <DateRangePicker v-model="range" />
      </template>
    </PageHeader>

    <div class="metric-cards">
      <MetricCard
        :label="t('dashboard.totalRevenueMetric')"
        :value="overview ? formatCurrency(overview.orders.summary.total_revenue) : '—'"
        :trend="
          overview
            ? { current: overview.orders.summary.total_revenue, previous: overview.orders.previous_period.total_revenue, caption: t('dashboard.previousPeriodCaption') }
            : null
        "
      />
      <MetricCard
        :label="t('dashboard.totalOrdersMetric')"
        :value="overview ? formatNumber(overview.orders.summary.total_orders) : '—'"
        :trend="
          overview
            ? { current: overview.orders.summary.total_orders, previous: overview.orders.previous_period.total_orders, caption: t('dashboard.previousPeriodCaption') }
            : null
        "
      />
      <MetricCard :label="t('dashboard.activeCustomersMetric')" :value="overview ? formatNumber(overview.customers.summary.active_customers) : '—'" />
      <MetricCard
        :label="t('dashboard.totalDiscountedMetric')"
        :value="overview ? formatCurrency(overview.campaigns.summary.total_discounted_amount) : '—'"
        :trend="
          overview
            ? {
                current: overview.campaigns.summary.total_discounted_amount,
                previous: overview.campaigns.previous_period.total_discounted_amount,
                caption: t('dashboard.previousPeriodCaption'),
              }
            : null
        "
      />
      <MetricCard :label="t('dashboard.activeCampaignsMetric')" :value="overview ? formatNumber(overview.campaigns.summary.active_campaigns) : '—'" />
      <MetricCard
        :label="t('dashboard.totalRedemptionsMetric')"
        :value="overview ? formatNumber(overview.campaigns.summary.total_redemptions) : '—'"
        :trend="
          overview
            ? {
                current: overview.campaigns.summary.total_redemptions,
                previous: overview.campaigns.previous_period.total_redemptions,
                caption: t('dashboard.previousPeriodCaption'),
              }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('dashboard.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="formatTooltipValue" />
        <p v-else-if="!overviewLoading" class="empty-hint">{{ t('dashboard.noChartData') }}</p>
      </template>
    </BaseCard>

    <div class="widgets-row">
      <BaseCard class="section-card widget-card">
        <template #title>{{ t('dashboard.attentionTitle') }}</template>
        <template #content>
          <ul v-if="attentionItems.length" class="attention-list">
            <li v-for="item in attentionItems" :key="`${item.type}-${item.id}`" class="attention-item">
              <button type="button" class="attention-item__link" @click="viewAttentionItem(item)">
                <DiscountKindTag v-if="item.type === 'discount'" :kind="item.kind" />
                <BaseTag v-else severity="secondary" :value="t('dashboard.campaignTag')" />
                <span class="attention-item__name">{{ item.name }}</span>
                <span class="attention-item__ends">{{ endsInLabel(item.until) }} · {{ formatMonthDayYear(item.until, auth.project?.timezone) }}</span>
              </button>
            </li>
          </ul>
          <p v-else-if="!attentionLoading" class="empty-hint">{{ t('dashboard.attentionEmpty') }}</p>
        </template>
      </BaseCard>

      <BaseCard class="section-card widget-card">
        <template #title>
          <div class="card-title-row">
            {{ t('dashboard.recentOrdersTitle') }}
            <BaseButton text size="small" :label="t('dashboard.viewAllOrdersButton')" @click="viewAllOrders" />
          </div>
        </template>
        <template #content>
          <BaseTable
            :data="recentOrders || []"
            :columns="recentOrdersColumns"
            :loading="recentOrdersLoading"
            row-key="id"
            @row-click="viewOrder($event.data)"
          >
            <template #cell-customer="{ data }">
              <EntityLink @click="viewCustomer(data.customer)">{{ data.customer.external_id }}</EntityLink>
            </template>
            <template #cell-total_amount="{ data }">{{ formatCurrency(data.total_amount) }}</template>
            <template #cell-status="{ data }"><OrderStatusTag :status="data.status" /></template>
            <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at, auth.project?.timezone) }}</template>
            <template #empty>{{ t('dashboard.recentOrdersEmpty') }}</template>
          </BaseTable>
        </template>
      </BaseCard>
    </div>
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

.widgets-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
  gap: 1.5rem;
  align-items: start;
}

.widget-card {
  margin-bottom: 0;
}

.card-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.attention-list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.attention-item__link {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  width: 100%;
  padding: 0.5rem;
  border: none;
  background: transparent;
  border-radius: var(--radius-sm);
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s;
}

.attention-item__link:hover {
  background: var(--color-bg-subtle);
}

.attention-item__link:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 1px;
}

.attention-item__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.attention-item__ends {
  flex-shrink: 0;
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}
</style>
