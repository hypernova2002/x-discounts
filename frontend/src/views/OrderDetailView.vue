<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import EntityLink from '@/components/EntityLink.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseCheckbox from '@/components/base/BaseCheckbox.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getOrder, cancelOrder } from '@/api/orders'
import { refundDiscount, refundPointsRedemption } from '@/api/refunds'
import { OrderCancelInputSchema } from '@/models/order'
import { refundInputSchema } from '@/models/refund'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatDateTime } from '@/lib/format'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const order = ref(null)
const loading = ref(false)
const loadError = ref('')

async function loadOrder() {
  loading.value = true
  loadError.value = ''
  try {
    order.value = await getOrder(route.params.id, { token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('orderDetail.loadError')
  } finally {
    loading.value = false
  }
}

function discountAmount(discount) {
  if (discount.amount_off != null) return t('orderDetail.amountOff', { amount: formatNumber(discount.amount_off) })
  if (discount.free_items?.length) return discount.free_items.map((f) => t('orderDetail.freeItem', { quantity: formatNumber(f.quantity), sku: f.sku })).join(', ')
  if (discount.points_earned != null) return t('orderDetail.pointsEarnedAmount', { points: formatNumber(discount.points_earned) })
  if (discount.effect_type === 'points_multiplier') return t('orderDetail.multiplierApplied')
  return ''
}

// --- receipt grouping: which discounts belong to which line item vs. the cart as a whole ---

const loyaltyDiscounts = computed(() => (order.value?.discounts || []).filter((d) => d.kind === 'loyalty'))
const cartDiscounts = computed(() => (order.value?.discounts || []).filter((d) => d.kind !== 'loyalty' && !d.sku))
function lineItemDiscounts(sku) {
  return (order.value?.discounts || []).filter((d) => d.kind !== 'loyalty' && d.sku === sku)
}

function remainingRefundable(discount) {
  if (discount.amount_off != null) return discount.amount_off - discount.refunded_amount_off
  if (discount.points_earned != null) return discount.points_earned - discount.refunded_points
  return 0
}

function refundedSoFar(discount) {
  if (discount.amount_off != null) return t('orderDetail.refundedOf', { refunded: formatNumber(discount.refunded_amount_off), total: formatNumber(discount.amount_off) })
  if (discount.points_earned != null) return t('orderDetail.refundedOf', { refunded: formatNumber(discount.refunded_points), total: formatNumber(discount.points_earned) })
  return '—'
}

function canRefundLine(discount) {
  return (discount.amount_off != null || discount.points_earned != null) && remainingRefundable(discount) > 0
}

function viewCustomer() {
  router.push({ name: 'customer-show', params: { id: order.value.customer.id } })
}

// --- cancel order ---

const cancelDialogOpen = ref(false)
const cancelRefund = ref(true)
const cancelReason = ref('')
const cancelling = ref(false)
const cancelErrors = ref({})

function openCancel() {
  cancelRefund.value = true
  cancelReason.value = ''
  cancelErrors.value = {}
  cancelDialogOpen.value = true
}

async function submitCancel() {
  cancelErrors.value = {}

  const payload = { refund: cancelRefund.value, reason: cancelReason.value || null }
  const result = OrderCancelInputSchema.safeParse(payload)
  if (!result.success) {
    cancelErrors.value = toFieldErrors(result.error)
    return
  }

  cancelling.value = true
  try {
    order.value = await cancelOrder(order.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('orderDetail.orderCancelled'), life: 3000 })
    cancelDialogOpen.value = false
  } catch (e) {
    toast.add({ severity: 'error', summary: t('orderDetail.cancelOrderError'), detail: e.message, life: 4000 })
  } finally {
    cancelling.value = false
  }
}

// --- refund a single line (an order_discount or the points redemption) ---

const refundTarget = ref(null)
const refundAmount = ref(null)
const refundReason = ref('')
const refunding = ref(false)
const refundError = ref('')
const refundErrors = ref({})

const refundAmountError = computed(() => (refundTarget.value ? refundErrors.value[refundTarget.value.unit] : null))

function openRefundDiscount(discount) {
  refundTarget.value = { kind: 'order_discount', id: discount.id, label: discount.discount_name, unit: discount.points_earned != null ? 'points' : 'amount_off' }
  refundAmount.value = remainingRefundable(discount)
  refundReason.value = ''
  refundError.value = ''
  refundErrors.value = {}
}

function openRefundPoints() {
  const pr = order.value.points_redemption
  refundTarget.value = { kind: 'points_redemption', id: pr.id, label: t('orderDetail.loyaltyPointsRedeemedLabel'), unit: 'points' }
  refundAmount.value = pr.points_redeemed - pr.refunded_points
  refundReason.value = ''
  refundError.value = ''
  refundErrors.value = {}
}

async function submitRefund() {
  refundError.value = ''
  refundErrors.value = {}

  const unit = refundTarget.value.unit
  const payload = { [unit]: refundAmount.value, reason: refundReason.value || null }
  const result = refundInputSchema(t, unit).safeParse(payload)
  if (!result.success) {
    refundErrors.value = toFieldErrors(result.error)
    return
  }

  refunding.value = true
  try {
    const refund = refundTarget.value.kind === 'order_discount' ? refundDiscount : refundPointsRedemption
    await refund(refundTarget.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('orderDetail.refunded'), life: 3000 })
    refundTarget.value = null
    await loadOrder()
  } catch (e) {
    refundError.value = e instanceof ApiError ? e.message : t('orderDetail.genericError')
  } finally {
    refunding.value = false
  }
}

// --- refund history viewer (read-only) ---

const historyTarget = ref(null)
function openHistory(discountOrRedemption, label) {
  historyTarget.value = { label, entries: discountOrRedemption.refund_history }
}

const pointsRedemptionRemaining = computed(() => {
  const pr = order.value?.points_redemption
  return pr ? pr.points_redeemed - pr.refunded_points : 0
})

onMounted(loadOrder)
</script>

<template>
  <AppShell>
    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <template v-if="order">
      <PageHeader>
        <template #title>
          <h2>{{ $t('orderDetail.orderTitle', { id: order.id }) }}</h2>
          <BaseTag v-if="order.cancelled_at" severity="danger" :value="$t('orderDetail.cancelledTag')" />
        </template>
        <template #actions>
          <span class="page-header__date">{{ formatDateTime(order.created_at) }}</span>
          <BaseButton v-if="!order.cancelled_at" text severity="danger" :label="$t('orderDetail.cancelButton')" @click="openCancel" />
        </template>
      </PageHeader>

      <BaseMessage v-if="order.cancelled_at" severity="warn" :closable="false">
        {{ $t('orderDetail.cancelledOn', { date: formatDateTime(order.cancelled_at) }) }}
      </BaseMessage>

      <div class="detail-grid">
        <BaseCard>
          <template #title>{{ $t('orderDetail.customer.title') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('orderDetail.customer.externalId') }}</dt>
              <dd><EntityLink @click="viewCustomer">{{ order.customer.external_id }}</EntityLink></dd>
              <template v-if="order.customer.name">
                <dt>{{ $t('orderDetail.customer.name') }}</dt>
                <dd>{{ order.customer.name }}</dd>
              </template>
              <template v-if="order.customer.email">
                <dt>{{ $t('orderDetail.customer.email') }}</dt>
                <dd><EntityLink @click="viewCustomer">{{ order.customer.email }}</EntityLink></dd>
              </template>
              <template v-if="order.customer.phone_number">
                <dt>{{ $t('orderDetail.customer.phone') }}</dt>
                <dd>{{ order.customer.phone_number }}</dd>
              </template>
              <template v-if="order.customer.country">
                <dt>{{ $t('orderDetail.customer.country') }}</dt>
                <dd>{{ order.customer.country }}</dd>
              </template>
            </dl>
          </template>
        </BaseCard>

        <BaseCard>
          <template #title>{{ $t('orderDetail.totals.title') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('orderDetail.totals.total') }}</dt>
              <dd>{{ formatNumber(order.total_amount) }}</dd>
              <dt>{{ $t('orderDetail.totals.discount') }}</dt>
              <dd>{{ formatNumber(order.total_discount_amount) }}</dd>
              <dt>{{ $t('orderDetail.totals.pointsEarned') }}</dt>
              <dd>{{ formatNumber(order.total_points_earned) }}</dd>
            </dl>
          </template>
        </BaseCard>
      </div>

      <BaseCard class="section-card">
        <template #title>{{ $t('orderDetail.receipt.title') }}</template>
        <template #content>
          <div v-for="li in order.line_items" :key="li.sku" class="receipt-line-item">
            <div class="receipt-line-item__header">
              <span class="receipt-line-item__sku">{{ li.sku }}</span>
              <span>{{ formatNumber(li.quantity) }} × {{ formatNumber(li.unit_price) }}</span>
            </div>
            <ul v-if="lineItemDiscounts(li.sku).length" class="receipt-discount-list">
              <li v-for="d in lineItemDiscounts(li.sku)" :key="d.id" class="receipt-discount-row">
                <span class="receipt-discount-row__name">{{ d.discount_name }} — {{ discountAmount(d) }}</span>
                <span class="receipt-discount-row__actions">
                  <span v-if="d.refunded_amount_off || d.refunded_points" class="refunded-note">
                    {{ $t('orderDetail.refundedNote', { detail: refundedSoFar(d) }) }}
                    <a href="#" @click.prevent="openHistory(d, d.discount_name)">{{ $t('orderDetail.historyLink') }}</a>
                  </span>
                  <BaseButton
                    v-if="canRefundLine(d)"
                    text
                    size="small"
                    :label="d.refundable ? $t('orderDetail.refundButton') : $t('orderDetail.refundOverrideButton')"
                    @click="openRefundDiscount(d)"
                  />
                </span>
              </li>
            </ul>
          </div>

          <div v-if="cartDiscounts.length" class="receipt-section">
            <h4>{{ $t('orderDetail.receipt.cartWideDiscounts') }}</h4>
            <ul class="receipt-discount-list">
              <li v-for="d in cartDiscounts" :key="d.id" class="receipt-discount-row">
                <span class="receipt-discount-row__name">{{ d.discount_name }} — {{ discountAmount(d) }}</span>
                <span class="receipt-discount-row__actions">
                  <span v-if="d.refunded_amount_off || d.refunded_points" class="refunded-note">
                    {{ $t('orderDetail.refundedNote', { detail: refundedSoFar(d) }) }}
                    <a href="#" @click.prevent="openHistory(d, d.discount_name)">{{ $t('orderDetail.historyLink') }}</a>
                  </span>
                  <BaseButton
                    v-if="canRefundLine(d)"
                    text
                    size="small"
                    :label="d.refundable ? $t('orderDetail.refundButton') : $t('orderDetail.refundOverrideButton')"
                    @click="openRefundDiscount(d)"
                  />
                </span>
              </li>
            </ul>
          </div>

          <div v-if="loyaltyDiscounts.length" class="receipt-section">
            <h4>{{ $t('orderDetail.receipt.loyaltyPointsEarned') }}</h4>
            <ul class="receipt-discount-list">
              <li v-for="d in loyaltyDiscounts" :key="d.id" class="receipt-discount-row">
                <span class="receipt-discount-row__name">{{ d.discount_name }} — {{ discountAmount(d) }}</span>
                <span v-if="d.refunded_points" class="refunded-note">
                  {{ $t('orderDetail.refundedNote', { detail: refundedSoFar(d) }) }}
                  <a href="#" @click.prevent="openHistory(d, d.discount_name)">{{ $t('orderDetail.historyLink') }}</a>
                </span>
              </li>
            </ul>
          </div>

          <div v-if="order.points_redemption" class="receipt-section">
            <h4>{{ $t('orderDetail.receipt.pointsRedemption') }}</h4>
            <div class="receipt-discount-row">
              <span class="receipt-discount-row__name">
                {{ $t('orderDetail.pointsRedemptionSummary', { points: formatNumber(order.points_redemption.points_redeemed), amount: formatNumber(order.points_redemption.amount_off) }) }}
              </span>
              <span class="receipt-discount-row__actions">
                <span v-if="order.points_redemption.refunded_points" class="refunded-note">
                  {{ $t('orderDetail.refundedNote', { detail: $t('orderDetail.refundedOf', { refunded: formatNumber(order.points_redemption.refunded_points), total: formatNumber(order.points_redemption.points_redeemed) }) }) }}
                  <a href="#" @click.prevent="openHistory(order.points_redemption, $t('orderDetail.loyaltyPointsRedeemedLabel'))">{{ $t('orderDetail.historyLink') }}</a>
                </span>
                <BaseButton v-if="pointsRedemptionRemaining > 0" text size="small" :label="$t('orderDetail.refundButton')" @click="openRefundPoints" />
              </span>
            </div>
          </div>
        </template>
      </BaseCard>
    </template>

    <BaseDialog v-model:visible="cancelDialogOpen" modal :header="$t('orderDetail.cancelDialog.header')" :style="{ width: '24rem' }">
      <div class="dialog-form">
        <div class="dialog-field--check">
          <BaseCheckbox v-model="cancelRefund" binary input-id="cancel_refund" />
          <label for="cancel_refund">{{ $t('orderDetail.cancelDialog.refundCheckboxLabel') }}</label>
        </div>
        <label>{{ $t('orderDetail.reasonLabel') }}</label>
        <BaseInputText v-model="cancelReason" :placeholder="$t('orderDetail.cancelDialog.reasonPlaceholder')" />
        <BaseButton :label="$t('orderDetail.cancelButton')" severity="danger" :loading="cancelling" @click="submitCancel" />
      </div>
    </BaseDialog>

    <BaseDialog :visible="!!refundTarget" modal :header="$t('orderDetail.refundDialog.header')" :style="{ width: '24rem' }" @update:visible="refundTarget = null">
      <div v-if="refundTarget" class="dialog-form">
        <p class="dialog-hint">{{ refundTarget.label }}</p>
        <label>{{ $t('orderDetail.refundDialog.amountLabel') }}</label>
        <BaseInputNumber v-model="refundAmount" :min="0" :max-fraction-digits="2" :invalid="!!refundAmountError" />
        <small v-if="refundAmountError" class="field-error">{{ refundAmountError }}</small>
        <label>{{ $t('orderDetail.reasonLabel') }}</label>
        <BaseInputText v-model="refundReason" :placeholder="$t('orderDetail.refundDialog.reasonPlaceholder')" />
        <BaseMessage v-if="refundError" severity="error" :closable="false">{{ refundError }}</BaseMessage>
        <BaseButton :label="$t('orderDetail.refundButton')" :loading="refunding" @click="submitRefund" />
      </div>
    </BaseDialog>

    <BaseDialog :visible="!!historyTarget" modal :header="$t('orderDetail.historyDialog.header')" :style="{ width: '28rem' }" @update:visible="historyTarget = null">
      <div v-if="historyTarget" class="dialog-form">
        <p class="dialog-hint">{{ historyTarget.label }}</p>
        <p v-if="!historyTarget.entries.length" class="empty-hint">{{ $t('orderDetail.historyDialog.empty') }}</p>
        <div v-for="(entry, i) in historyTarget.entries" :key="i" class="history-entry">
          <div class="history-entry__amount">
            {{ entry.amount_off != null ? $t('orderDetail.amountOff', { amount: formatNumber(entry.amount_off) }) : $t('orderDetail.pointsAmount', { points: formatNumber(entry.points) }) }}
            <span class="history-entry__date">{{ formatDateTime(entry.refunded_at) }}</span>
          </div>
          <div v-if="entry.reason" class="history-entry__reason">"{{ entry.reason }}"</div>
          <div class="history-entry__actor">{{ $t('orderDetail.byActor', { actor: entry.performed_by || $t('orderDetail.unknownActor') }) }}</div>
        </div>
      </div>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.page-header__date {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
}

.dialog-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.dialog-field--check {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
}

.dialog-hint {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
  margin: 0;
}

.field-error {
  color: var(--p-red-500, #ef4444);
  font-size: 0.8125rem;
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

.receipt-line-item {
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--p-content-border-color, #e5e7eb);
}

.receipt-line-item:last-of-type {
  border-bottom: none;
}

.receipt-line-item__header {
  display: flex;
  justify-content: space-between;
  font-weight: 600;
}

.receipt-line-item__sku {
  font-family: monospace;
}

.receipt-section {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--p-content-border-color, #e5e7eb);
}

.receipt-section h4 {
  margin: 0 0 0.5rem;
  font-size: 0.875rem;
  color: var(--p-text-muted-color, #6b7280);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.receipt-discount-list {
  list-style: none;
  margin: 0.25rem 0 0;
  padding: 0 0 0 1rem;
}

.receipt-discount-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  font-size: 0.9375rem;
  padding: 0.25rem 0;
}

.receipt-discount-row__actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.refunded-note {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.8125rem;
}

.refunded-note a {
  color: var(--p-primary-color, #10b981);
  text-decoration: none;
}

.history-entry {
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--p-content-border-color, #e5e7eb);
}

.history-entry:last-child {
  border-bottom: none;
}

.history-entry__amount {
  display: flex;
  justify-content: space-between;
  font-weight: 600;
}

.history-entry__date {
  font-weight: 400;
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.8125rem;
}

.history-entry__reason {
  font-style: italic;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.history-entry__actor {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.8125rem;
  margin-top: 0.125rem;
}
</style>
