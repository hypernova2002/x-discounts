<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import EntityLink from '@/components/EntityLink.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseTimeline from '@/components/base/BaseTimeline.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getCustomer, updateCustomer, grantPoints as grantPointsRequest } from '@/api/customers'
import { listOrders } from '@/api/orders'
import { listMembershipSchemes } from '@/api/membershipSchemes'
import { grantPointsInputSchema } from '@/models/customer'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast.js'
import { formatNumber, formatDate, formatDateTime } from '@/lib/format'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const customer = ref(null)
const loadError = ref('')
const tierOptions = ref([])
const savingMembership = ref(false)
const orders = ref([])
const ordersLoading = ref(false)

async function loadCustomer() {
  loadError.value = ''
  try {
    customer.value = await getCustomer(route.params.id, { token: auth.token, projectId: auth.project?.id })
    await Promise.all([loadTierOptions(), loadOrders()])
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('customerDetail.loadError')
  }
}

async function loadOrders() {
  ordersLoading.value = true
  try {
    orders.value = await listOrders({ customerExternalId: customer.value.external_id, token: auth.token, projectId: auth.project?.id })
  } finally {
    ordersLoading.value = false
  }
}

const ACTIVITY_LABELS = computed(() => ({
  order: t('customerDetail.activityLabels.order'),
  gift_shop_redemption: t('customerDetail.activityLabels.giftShopRedemption'),
  membership: t('customerDetail.activityLabels.membership'),
}))
const ACTIVITY_SEVERITIES = {
  order: 'success',
  gift_shop_redemption: 'info',
  membership: 'warn',
}

function viewOrder(orderId) {
  router.push({ name: 'order-show', params: { id: orderId } })
}

const loyaltyPointLotColumns = computed(() => [
  {
    field: 'source',
    header: t('customerDetail.loyaltyPoints.source'),
    hideable: false,
    filterOptions: [
      { label: t('customerDetail.loyaltyPoints.order'), value: 'order' },
      { label: t('customerDetail.loyaltyPoints.manualGrant'), value: 'manual_grant' },
      { label: t('customerDetail.loyaltyPoints.redemptionRefund'), value: 'redemption_refund' },
      { label: t('customerDetail.loyaltyPoints.legacy'), value: 'legacy_backfill' },
    ],
  },
  { field: 'points', header: t('customerDetail.loyaltyPoints.earned'), sortable: true },
  { field: 'points_remaining', header: t('customerDetail.loyaltyPoints.remaining'), sortable: true },
  {
    field: 'status',
    header: t('customerDetail.loyaltyPoints.status'),
    filterOptions: [
      { label: t('customerDetail.loyaltyPoints.statusActive'), value: 'active' },
      { label: t('customerDetail.loyaltyPoints.statusExpired'), value: 'expired' },
      { label: t('customerDetail.loyaltyPoints.statusCancelled'), value: 'cancelled' },
    ],
  },
  { field: 'earned_at', header: t('customerDetail.loyaltyPoints.earnedAt'), sortable: true },
  { field: 'expires_at', header: t('customerDetail.loyaltyPoints.expires'), sortable: true },
])

const customerOrderColumns = computed(() => [
  { field: 'id', header: t('customerDetail.orders.order'), sortable: true, hideable: false },
  { field: 'created_at', header: t('customerDetail.orders.placed'), sortable: true },
  { field: 'total_amount', header: t('customerDetail.orders.total'), sortable: true },
  { field: 'total_discount_amount', header: t('customerDetail.orders.discount'), sortable: true },
  { field: 'total_points_earned', header: t('customerDetail.orders.pointsEarned'), sortable: true },
  { field: 'total_points_redeemed', header: t('customerDetail.orders.pointsRedeemed'), sortable: true },
])

async function loadTierOptions() {
  const schemes = await listMembershipSchemes({ perPage: 500, token: auth.token, projectId: auth.project?.id })
  tierOptions.value = schemes.flatMap((scheme) => scheme.tiers.map((tier) => ({ label: `${scheme.name} — ${tier.name}`, value: tier.id })))
}

async function setMembershipTier(tierId) {
  savingMembership.value = true
  try {
    // PATCH returns only the base customer fields, not stats/activity/loyalty_point_lots —
    // merge onto the existing detail object rather than replacing it wholesale.
    const updated = await updateCustomer(customer.value.id, { membership_tier_id: tierId }, { token: auth.token, projectId: auth.project?.id })
    customer.value = { ...customer.value, ...updated }
    toast.add({ severity: 'success', summary: t('customerDetail.membershipUpdated'), life: 3000 })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('customerDetail.membershipUpdateError'), detail: e.message, life: 4000 })
  } finally {
    savingMembership.value = false
  }
}

// --- grant points ---

const grantDialogOpen = ref(false)
const grantPoints = ref(null)
const grantExpiresAt = ref('')
const grantReason = ref('')
const granting = ref(false)
const grantErrors = ref({})

function openGrantPoints() {
  grantPoints.value = null
  grantExpiresAt.value = ''
  grantReason.value = ''
  grantErrors.value = {}
  grantDialogOpen.value = true
}

async function submitGrantPoints() {
  grantErrors.value = {}

  const payload = {
    points: grantPoints.value,
    expires_at: grantExpiresAt.value ? `${grantExpiresAt.value}:00.000Z` : null,
    reason: grantReason.value || null,
  }

  const result = grantPointsInputSchema(t).safeParse(payload)
  if (!result.success) {
    grantErrors.value = toFieldErrors(result.error)
    return
  }

  granting.value = true
  try {
    customer.value = await grantPointsRequest(customer.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('customerDetail.pointsGranted'), life: 3000 })
    grantDialogOpen.value = false
  } catch (e) {
    grantErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('customerDetail.genericError') }
  } finally {
    granting.value = false
  }
}

onMounted(loadCustomer)
</script>

<template>
  <AppShell>
    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <template v-if="customer">
      <PageHeader>
        <template #title>
          <h2>{{ customer.name || customer.external_id }}</h2>
        </template>
      </PageHeader>

      <div class="detail-grid">
        <BaseCard>
          <template #title>{{ $t('customerDetail.details.title') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('customerDetail.details.externalId') }}</dt>
              <dd>{{ customer.external_id }}</dd>
              <template v-if="customer.name">
                <dt>{{ $t('customerDetail.details.name') }}</dt>
                <dd>{{ customer.name }}</dd>
              </template>
              <template v-if="customer.email">
                <dt>{{ $t('customerDetail.details.email') }}</dt>
                <dd>{{ customer.email }}</dd>
              </template>
              <template v-if="customer.phone_number">
                <dt>{{ $t('customerDetail.details.phone') }}</dt>
                <dd>{{ customer.phone_number }}</dd>
              </template>
              <template v-if="customer.country">
                <dt>{{ $t('customerDetail.details.country') }}</dt>
                <dd>{{ customer.country }}</dd>
              </template>
              <template v-if="customer.date_of_birth">
                <dt>{{ $t('customerDetail.details.dateOfBirth') }}</dt>
                <dd>{{ customer.date_of_birth }}</dd>
              </template>
              <dt>{{ $t('customerDetail.details.marketingOptIn') }}</dt>
              <dd>{{ customer.marketing_opt_in ? $t('customerDetail.details.yes') : $t('customerDetail.details.no') }}</dd>
              <dt>{{ $t('customerDetail.details.customerSince') }}</dt>
              <dd>{{ formatDateTime(customer.created_at) }}</dd>
            </dl>
          </template>
        </BaseCard>

        <BaseCard>
          <template #title>{{ $t('customerDetail.totals.title') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('customerDetail.totals.orders') }}</dt>
              <dd>{{ formatNumber(customer.stats.order_count) }}</dd>
              <dt>{{ $t('customerDetail.totals.totalSpent') }}</dt>
              <dd>{{ formatNumber(customer.stats.total_spent) }}</dd>
              <dt>{{ $t('customerDetail.totals.totalDiscounts') }}</dt>
              <dd>{{ formatNumber(customer.stats.total_discount) }}</dd>
              <dt>{{ $t('customerDetail.totals.pointsBalance') }}</dt>
              <dd>{{ formatNumber(customer.stats.points_balance) }}</dd>
              <dt>{{ $t('customerDetail.totals.pointsEarnedLifetime') }}</dt>
              <dd>{{ formatNumber(customer.stats.total_points_earned) }}</dd>
              <dt>{{ $t('customerDetail.totals.pointsRedeemed') }}</dt>
              <dd>{{ formatNumber(customer.stats.total_points_redeemed) }}</dd>
              <template v-if="customer.stats.total_points_expired">
                <dt>{{ $t('customerDetail.totals.pointsExpired') }}</dt>
                <dd>{{ formatNumber(customer.stats.total_points_expired) }}</dd>
              </template>
            </dl>
          </template>
        </BaseCard>

        <BaseCard>
          <template #title>{{ $t('customerDetail.membership.title') }}</template>
          <template #content>
            <div class="membership-field">
              <BaseSelect
                :model-value="customer.membership_tier?.id ?? null"
                :options="tierOptions"
                option-label="label"
                option-value="value"
                :placeholder="$t('customerDetail.membership.noMembershipPlaceholder')"
                show-clear
                :loading="savingMembership"
                @update:model-value="setMembershipTier"
              />
            </div>
            <dl v-if="customer.membership_tier" class="details membership-details">
              <dt>{{ $t('customerDetail.membership.enteredOn') }}</dt>
              <dd>{{ customer.membership_tier_entered_at ? formatDate(customer.membership_tier_entered_at) : $t('customerDetail.membership.unknown') }}</dd>
              <template v-if="customer.membership_tier.grace_period_days && customer.membership_tier_entered_at">
                <dt>{{ $t('customerDetail.membership.protectedUntil') }}</dt>
                <dd>
                  {{
                    formatDate(
                      new Date(customer.membership_tier_entered_at).getTime() +
                        customer.membership_tier.grace_period_days * 86400000
                    )
                  }}
                </dd>
              </template>
            </dl>
          </template>
        </BaseCard>

        <BaseCard v-if="Object.keys(customer.metadata || {}).length">
          <template #title>{{ $t('customerDetail.customAttributes.title') }}</template>
          <template #content>
            <dl class="details">
              <template v-for="(value, key) in customer.metadata" :key="key">
                <dt>{{ key }}</dt>
                <dd>{{ value }}</dd>
              </template>
            </dl>
          </template>
        </BaseCard>
      </div>

      <BaseCard class="section-card">
        <template #title>{{ $t('customerDetail.activity.title') }}</template>
        <template #content>
          <p v-if="!customer.activity.length" class="empty-hint">{{ $t('customerDetail.activity.empty') }}</p>
          <BaseTimeline v-else :value="customer.activity">
            <template #opposite="{ item }">
              <span class="activity-date">{{ formatDateTime(item.occurred_at) }}</span>
            </template>
            <template #content="{ item }">
              <div class="activity-entry">
                <BaseTag :severity="ACTIVITY_SEVERITIES[item.type]" :value="ACTIVITY_LABELS[item.type]" />

                <template v-if="item.type === 'order'">
                  <EntityLink @click="viewOrder(item.order_id)">{{ item.order_id }}</EntityLink>
                  <span>{{ $t('customerDetail.activity.orderSummary', { total: formatNumber(item.total_amount), discount: formatNumber(item.total_discount_amount) }) }}</span>
                  <span v-if="item.total_points_earned">{{ $t('customerDetail.activity.pointsEarnedSuffix', { points: formatNumber(item.total_points_earned) }) }}</span>
                  <span v-if="item.total_points_redeemed">{{ $t('customerDetail.activity.pointsRedeemedSuffix', { points: formatNumber(item.total_points_redeemed) }) }}</span>
                </template>

                <template v-else-if="item.type === 'gift_shop_redemption'">
                  <span>{{ $t('customerDetail.activity.giftShopRedemption', { quantity: formatNumber(item.quantity), item: item.item_name, points: formatNumber(item.points_spent) }) }}</span>
                </template>

                <template v-else-if="item.type === 'membership'">
                  <span>{{ $t('customerDetail.activity.membershipJoined', { scheme: item.scheme_name, tier: item.tier_name }) }}</span>
                </template>
              </div>
            </template>
          </BaseTimeline>
        </template>
      </BaseCard>

      <BaseCard class="section-card">
        <template #title>
          <div class="card-title-row">
            <span>{{ $t('customerDetail.loyaltyPoints.title') }}</span>
            <BaseButton text size="small" :label="$t('customerDetail.loyaltyPoints.grantButton')" @click="openGrantPoints" />
          </div>
        </template>
        <template #content>
          <BaseTable :data="customer.loyalty_point_lots" :columns="loyaltyPointLotColumns" row-key="id" @refresh="loadCustomer">
            <template #cell-source="{ data }">
              <span v-if="data.source === 'order'">{{ data.discount_name }}</span>
              <span v-else-if="data.source === 'manual_grant'">{{ $t('customerDetail.loyaltyPoints.manualGrant') }}</span>
              <span v-else-if="data.source === 'redemption_refund'">{{ $t('customerDetail.loyaltyPoints.redemptionRefund') }}</span>
              <span v-else>{{ $t('customerDetail.loyaltyPoints.legacy') }}</span>
              <div v-if="data.reason || data.performed_by" class="lot-detail">
                <template v-if="data.reason">"{{ data.reason }}"</template>
                <template v-if="data.performed_by"> — {{ data.performed_by }}</template>
              </div>
            </template>
            <template #cell-points="{ data }">{{ formatNumber(data.points) }}</template>
            <template #cell-points_remaining="{ data }">{{ formatNumber(data.points_remaining) }}</template>
            <template #cell-status="{ data }">
              <BaseTag
                :severity="{ active: 'success', expired: 'secondary', cancelled: 'danger' }[data.status]"
                :value="data.status"
              />
            </template>
            <template #cell-earned_at="{ data }">{{ formatDateTime(data.earned_at) }}</template>
            <template #cell-expires_at="{ data }">
              <span v-if="!data.expires_at">{{ $t('customerDetail.loyaltyPoints.never') }}</span>
              <span v-else>{{ formatDate(data.expires_at) }}</span>
            </template>
            <template #empty>{{ $t('customerDetail.loyaltyPoints.empty') }}</template>
          </BaseTable>
        </template>
      </BaseCard>

      <BaseDialog v-model:visible="grantDialogOpen" modal :header="$t('customerDetail.grantDialog.header')" :style="{ width: '24rem' }">
        <div class="dialog-form">
          <label>{{ $t('customerDetail.grantDialog.pointsLabel') }}</label>
          <BaseInputNumber v-model="grantPoints" :min="1" :invalid="!!grantErrors.points" />
          <small v-if="grantErrors.points" class="field-error">{{ grantErrors.points }}</small>
          <label>{{ $t('customerDetail.grantDialog.expiresLabel') }}</label>
          <BaseInputText v-model="grantExpiresAt" type="datetime-local" />
          <label>{{ $t('customerDetail.grantDialog.reasonLabel') }}</label>
          <BaseInputText v-model="grantReason" :placeholder="$t('customerDetail.grantDialog.reasonPlaceholder')" />
          <BaseMessage v-if="grantErrors._root" severity="error" :closable="false">{{ grantErrors._root }}</BaseMessage>
          <BaseButton :label="$t('customerDetail.grantDialog.submit')" :loading="granting" @click="submitGrantPoints" />
        </div>
      </BaseDialog>

      <BaseCard class="section-card">
        <template #title>{{ $t('customerDetail.orders.title') }}</template>
        <template #content>
          <BaseTable :data="orders" :columns="customerOrderColumns" :loading="ordersLoading" row-key="id" @row-click="viewOrder($event.data.id)" @refresh="loadOrders">
            <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at) }}</template>
            <template #cell-total_amount="{ data }">{{ formatNumber(data.total_amount) }}</template>
            <template #cell-total_discount_amount="{ data }">{{ formatNumber(data.total_discount_amount) }}</template>
            <template #cell-total_points_earned="{ data }">{{ formatNumber(data.total_points_earned) }}</template>
            <template #cell-total_points_redeemed="{ data }">{{ formatNumber(data.total_points_redeemed) }}</template>
            <template #empty>{{ $t('customerDetail.orders.empty') }}</template>
          </BaseTable>
        </template>
      </BaseCard>
    </template>
  </AppShell>
</template>

<style scoped>
.membership-field {
  display: flex;
}

.membership-details {
  margin-top: 0.75rem;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.empty-hint {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
  margin: 0;
}

.activity-date {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.8125rem;
  white-space: nowrap;
}

.activity-entry {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9375rem;
  padding-bottom: 1rem;
}

.card-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.dialog-form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.lot-detail {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.8125rem;
  font-style: italic;
}

.field-error {
  color: var(--p-red-500, #ef4444);
  font-size: 0.8125rem;
}
</style>
