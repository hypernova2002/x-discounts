<script setup>
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseProgressBar from '@/components/base/BaseProgressBar.vue'
import EntityLink from '@/components/EntityLink.vue'
import LifecycleStatus from '@/components/LifecycleStatus.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listDiscounts } from '@/api/discounts'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatMonthDayYear, formatNumber } from '@/lib/format'

// Mountable section shared by CouponsView/PromotionsView/LoyaltyPointsView —
// `kind` picks which discounts show and which of their own validity fields
// apply (promotion/loyalty: active_from/active_until, coupon: valid_from/
// valid_until — see models/discount.js's per-kind kind_config shape).
const props = defineProps({ kind: { type: String, required: true } })

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { data: discounts, loading, error, reload } = useAsync(() => listDiscounts({ kind: props.kind, token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('discountKindTable.loadError'), detail: e.message, life: 4000 })
})

function validityFields(discount) {
  if (discount.kind === 'coupon') return { from: discount.coupon?.valid_from, until: discount.coupon?.valid_until }
  return { from: discount[discount.kind]?.active_from, until: discount[discount.kind]?.active_until }
}

// Usage against `max_redemptions` (an optional overall cap shared by every
// kind, set in the discount form's Usage limits section) — 0-100, clamped in
// case redemption_count ever exceeds the cap (e.g. the cap was lowered after
// the fact). `null` (not 0) when there's no cap, so the cell can tell
// "unlimited" apart from "0% used".
function usagePercent(discount) {
  if (!discount.max_redemptions) return null
  return Math.min(100, Math.round((discount.redemption_count / discount.max_redemptions) * 100))
}

const columns = computed(() => [
  { field: 'name', header: t('discountKindTable.nameColumn'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'campaign', header: t('discountKindTable.campaignColumn'), filter: { type: 'string', accessor: (row) => row.campaign.name } },
  { field: 'redemption_count', header: t('discountKindTable.redemptionsColumn'), sortable: true, filter: { type: 'number' } },
  { field: 'usage', header: t('discountKindTable.usageColumn') },
  { field: 'start_date', header: t('discountKindTable.startDateColumn'), filter: { type: 'date', accessor: (row) => validityFields(row).from } },
  { field: 'end_date', header: t('discountKindTable.endDateColumn'), filter: { type: 'date', accessor: (row) => validityFields(row).until } },
  { field: 'status', header: t('discountKindTable.statusColumn'), hideable: false },
  { field: 'actions', header: t('discountKindTable.actionsColumn'), hideable: false },
])

function viewDiscount(discount) {
  router.push({ name: 'discount-show', params: { id: discount.id } })
}

function editDiscount(discount) {
  router.push({ name: 'discount-edit', params: { id: discount.id } })
}

function viewCampaign(campaign) {
  router.push({ name: 'campaign-show', params: { id: campaign.id } })
}
</script>

<template>
  <BaseTable
    :data="discounts || []"
    :columns="columns"
    :loading="loading"
    row-key="id"
    :search-placeholder="t('discountKindTable.searchPlaceholder')"
    @row-click="viewDiscount($event.data)"
    @refresh="reload"
  >
    <template #cell-campaign="{ data }">
      <EntityLink @click="viewCampaign(data.campaign)">{{ data.campaign.name }}</EntityLink>
    </template>
    <template #cell-usage="{ data }">
      <div v-if="usagePercent(data) !== null" class="usage-cell">
        <BaseProgressBar :value="usagePercent(data)" class="usage-cell__bar" />
        <span class="usage-cell__text">{{ t('discountKindTable.usageOfMax', { count: formatNumber(data.redemption_count), max: formatNumber(data.max_redemptions) }) }}</span>
      </div>
      <span v-else>{{ t('discountKindTable.usageUnlimited') }}</span>
    </template>
    <template #cell-start_date="{ data }">{{ validityFields(data).from ? formatMonthDayYear(validityFields(data).from, auth.project?.timezone) : '—' }}</template>
    <template #cell-end_date="{ data }">{{ validityFields(data).until ? formatMonthDayYear(validityFields(data).until, auth.project?.timezone) : '—' }}</template>
    <template #cell-status="{ data }">
      <LifecycleStatus compact :enabled="data.enabled" :from="validityFields(data).from" :until="validityFields(data).until" />
    </template>
    <template #cell-actions="{ data }">
      <BaseButton text icon="pi pi-pencil" :aria-label="t('discountKindTable.editButton')" @click.stop="editDiscount(data)" />
    </template>
    <template #empty>{{ t('discountKindTable.emptyHint') }}</template>
  </BaseTable>
</template>

<style scoped>
.usage-cell {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 6rem;
}

.usage-cell__bar {
  width: 100%;
}

.usage-cell__text {
  font-size: var(--font-size-xs);
  color: var(--color-text-muted);
  font-variant-numeric: tabular-nums;
}
</style>
