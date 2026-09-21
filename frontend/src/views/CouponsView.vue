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
import { getCouponAnalytics } from '@/api/analytics'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatCalendarDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const range = ref(null)

const { data: analytics, loading, error, reload } = useAsync(
  () => (range.value ? getCouponAnalytics({ ...range.value, token: auth.token, projectId: auth.project?.id }) : Promise.resolve(null)),
  { immediate: false },
)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('coupons.analyticsLoadError'), detail: e.message, life: 4000 })
})

watch(range, () => {
  if (range.value) reload()
})

const chartLabels = computed(() => (analytics.value?.series || []).map((s) => formatCalendarDate(s.date)))
const chartDatasets = computed(() => [{ label: t('coupons.chartSeriesLabel'), data: (analytics.value?.series || []).map((s) => s.value) }])
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
      <MetricCard :label="t('coupons.totalCouponsMetric')" :value="analytics ? formatNumber(analytics.summary.total_coupons) : '—'" />
      <MetricCard
        :label="t('coupons.totalRedemptionsMetric')"
        :value="analytics ? formatNumber(analytics.summary.total_redemptions) : '—'"
        :trend="
          analytics
            ? {
                current: analytics.summary.total_redemptions,
                previous: analytics.previous_period.total_redemptions,
                caption: t('coupons.previousPeriodCaption'),
              }
            : null
        "
      />
    </div>

    <BaseCard class="section-card">
      <template #title>{{ t('coupons.chartTitle') }}</template>
      <template #content>
        <BaseChart v-if="hasChartData" :labels="chartLabels" :datasets="chartDatasets" :format-value="(v) => formatNumber(v)" />
        <p v-else-if="!loading" class="empty-hint">{{ t('coupons.noChartData') }}</p>
      </template>
    </BaseCard>

    <DiscountKindTable kind="coupon" />
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
