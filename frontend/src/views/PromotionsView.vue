<script setup>
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import DateRangePicker from '@/components/DateRangePicker.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import MetricCard from '@/components/base/MetricCard.vue'
import BaseChart from '@/components/base/BaseChart.vue'
import DiscountKindTable from '@/components/DiscountKindTable.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { getPromotionAnalytics } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatCurrency, formatCalendarDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const range = ref(null)

const { data: analytics, loading, error, reload } = useAsync(
  () => (range.value ? getPromotionAnalytics({ ...range.value, token: auth.token, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('promotions.analyticsLoadError'), detail: e.message, life: 4000 })
})

watch(range, () => {
  if (range.value) reload()
})

const chartLabels = computed(() => (analytics.value?.usage_series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [
  { label: t('promotions.usageSeriesLabel'), data: (analytics.value?.usage_series || []).map((s) => s.value), yAxisID: 'y' },
  { label: t('promotions.earningsSeriesLabel'), data: (analytics.value?.earnings_series || []).map((s) => s.value), yAxisID: 'y1' },
])
const hasChartData = computed(
  () => (analytics.value?.usage_series || []).some((s) => s.value > 0) || (analytics.value?.earnings_series || []).some((s) => s.value > 0),
)

function formatTooltipValue(value, datasetLabel) {
  return datasetLabel === t('promotions.earningsSeriesLabel') ? formatCurrency(value) : formatNumber(value)
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
      <MetricCard :label="t('promotions.totalRunningMetric')" :value="analytics ? formatNumber(analytics.summary.total_running_promotions) : '—'" />
      <MetricCard
        :label="t('promotions.totalDiscountsMetric')"
        :value="analytics ? formatCurrency(analytics.summary.total_discounts_from_promotions) : '—'"
        :trend="
          analytics
            ? {
                current: analytics.summary.total_discounts_from_promotions,
                previous: analytics.previous_period.total_discounts_from_promotions,
                caption: t('promotions.previousPeriodCaption'),
              }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('promotions.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="formatTooltipValue" />
        <p v-else-if="!loading" class="empty-hint">{{ t('promotions.noChartData') }}</p>
      </template>
    </BaseCard>

    <DiscountKindTable kind="promotion" />
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
