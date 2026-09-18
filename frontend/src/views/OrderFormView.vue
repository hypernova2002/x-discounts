<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BasePanel from '@/components/base/BasePanel.vue'
import KeyValueEditor from '@/components/discounts/KeyValueEditor.vue'
import CouponCodeSelect from '@/components/discounts/CouponCodeSelect.vue'
import DiscountRulesSummary from '@/components/discounts/DiscountRulesSummary.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { validateDiscounts, redeemDiscounts } from '@/api/discountRedemption'
import { discountRedemptionInputSchema } from '@/models/discountRedemption'
import { toFieldErrors } from '@/models/formErrors'
import { attrsToObject, lineItemsToPayload } from '@/services/cartAttrs'
import { useBaseToast } from '@/composables/useBaseToast'
import { useCoupons } from '@/composables/useCoupons'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()
const { coupons } = useCoupons()

function discountForCode(code) {
  return coupons().find((d) => d.coupon?.code === code)
}

function defaultLineItem() {
  return { sku: '', quantity: 1, unit_price: 0, attrs: [] }
}

const lineItems = ref([defaultLineItem()])
const cartAttrs = ref([])
const customerExternalId = ref('')
const customerName = ref('')
const customerEmail = ref('')
const customerAttrs = ref([])
const couponCodes = ref([])
const pendingCouponCode = ref(null)
const redeemPoints = ref(null)

function addLineItem() {
  lineItems.value = [...lineItems.value, defaultLineItem()]
}
function removeLineItem(index) {
  lineItems.value = lineItems.value.filter((_, i) => i !== index)
}

function addCouponCode(code) {
  if (!code || couponCodes.value.includes(code)) return
  couponCodes.value = [...couponCodes.value, code]
  pendingCouponCode.value = null
}
function removeCouponCode(code) {
  couponCodes.value = couponCodes.value.filter((c) => c !== code)
}

function buildPayload() {
  return {
    cart: attrsToObject(cartAttrs.value),
    line_items: lineItemsToPayload(lineItems.value),
    customer: {
      external_id: customerExternalId.value,
      ...(customerName.value ? { name: customerName.value } : {}),
      ...(customerEmail.value ? { email: customerEmail.value } : {}),
      ...attrsToObject(customerAttrs.value),
    },
    coupon_codes: couponCodes.value,
    redeem_points: Number(redeemPoints.value) || 0,
  }
}

// Discounts must be previewed — with the cart/customer/coupons exactly as they
// currently stand — before an order can be created. Deriving staleness from a
// structural comparison (rather than tracking edits via per-field event handlers)
// means it can't go out of sync with what was actually last previewed.
const previewing = ref(false)
const previewError = ref('')
const previewResult = ref(null)
const lastPreviewedPayload = ref(null)
const previewStale = computed(() => JSON.stringify(buildPayload()) !== lastPreviewedPayload.value)
const errors = ref({})

async function runPreview() {
  errors.value = {}

  const payload = buildPayload()
  const result = discountRedemptionInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  previewing.value = true
  previewError.value = ''
  try {
    previewResult.value = await validateDiscounts(result.data, { token: auth.token, projectId: auth.project?.id })
    lastPreviewedPayload.value = JSON.stringify(payload)
  } catch (e) {
    previewError.value = e instanceof ApiError ? e.message : t('orderForm.genericError')
    previewResult.value = null
  } finally {
    previewing.value = false
  }
}

const creating = ref(false)
const createError = ref('')

async function createOrder() {
  errors.value = {}

  const payload = buildPayload()
  const result = discountRedemptionInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  creating.value = true
  createError.value = ''
  try {
    const order = await redeemDiscounts(result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('orderForm.orderCreated'), life: 3000 })
    router.push({ name: 'order-show', params: { id: order.id } })
  } catch (e) {
    createError.value = e instanceof ApiError ? e.message : t('orderForm.genericError')
  } finally {
    creating.value = false
  }
}

function describeDiscount(d) {
  if (d.amount_off != null) return t('orderForm.amountOff', { amount: d.amount_off })
  if (d.free_items) return d.free_items.map((f) => t('orderForm.freeItem', { quantity: f.quantity, sku: f.sku })).join(', ')
  return ''
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <h2>{{ $t('orderForm.title') }}</h2>
      </template>
    </PageHeader>

    <BaseCard>
      <template #content>
        <div class="form-section">
          <h3>{{ $t('orderForm.lineItems.title') }}</h3>
          <div v-for="(li, i) in lineItems" :key="i" class="line-item-row">
            <BaseInputText v-model="li.sku" :placeholder="$t('orderForm.lineItems.skuPlaceholder')" />
            <BaseInputNumber v-model="li.quantity" :placeholder="$t('orderForm.lineItems.quantityPlaceholder')" :min="1" />
            <BaseInputNumber v-model="li.unit_price" :placeholder="$t('orderForm.lineItems.unitPricePlaceholder')" :min="0" :min-fraction-digits="2" />
            <BaseButton text severity="danger" icon="pi pi-times" @click="removeLineItem(i)" />
            <KeyValueEditor v-model="li.attrs" entity="line_item" class="line-item-row__attrs" />
          </div>
          <BaseButton size="small" text :label="$t('orderForm.lineItems.addButton')" @click="addLineItem" />
        </div>

        <div class="form-section">
          <h3>{{ $t('orderForm.cartAttributes.title') }}</h3>
          <KeyValueEditor v-model="cartAttrs" entity="cart" />
        </div>

        <div class="form-section">
          <h3>{{ $t('orderForm.customer.title') }}</h3>
          <label>{{ $t('orderForm.customer.externalIdLabel') }}</label>
          <BaseInputText v-model="customerExternalId" required />
          <label>{{ $t('orderForm.customer.nameLabel') }}</label>
          <BaseInputText v-model="customerName" :placeholder="$t('orderForm.customer.optionalPlaceholder')" />
          <label>{{ $t('orderForm.customer.emailLabel') }}</label>
          <BaseInputText v-model="customerEmail" :placeholder="$t('orderForm.customer.optionalPlaceholder')" />
          <KeyValueEditor v-model="customerAttrs" entity="customer" />
        </div>

        <div class="form-section coupon-section">
          <h3>{{ $t('orderForm.coupons.title') }}</h3>
          <BasePanel v-for="code in couponCodes" :key="code" toggleable collapsed class="coupon-panel">
            <template #header>
              <div class="coupon-row">
                <BaseTag :value="code" />
                <template v-if="previewResult">
                  <template v-if="previewResult.coupons.find((c) => c.code === code)?.valid">
                    <BaseTag severity="success" :value="$t('orderForm.coupons.valid')" />
                    <span
                      v-for="(d, i) in previewResult.coupons.find((c) => c.code === code).discounts"
                      :key="i"
                      class="coupon-effect"
                    >
                      {{ d.name }} — {{ describeDiscount(d) }}
                    </span>
                  </template>
                  <template v-else>
                    <BaseTag severity="danger" :value="$t('orderForm.coupons.invalid')" />
                    <span class="coupon-reason">{{ previewResult.coupons.find((c) => c.code === code)?.reason }}</span>
                  </template>
                </template>
                <BaseButton text severity="danger" icon="pi pi-times" @click.stop="removeCouponCode(code)" />
              </div>
            </template>
            <DiscountRulesSummary v-if="discountForCode(code)" :discount="discountForCode(code)" />
            <p v-else class="empty-hint">{{ $t('orderForm.coupons.rulesUnavailable') }}</p>
          </BasePanel>
          <CouponCodeSelect :model-value="pendingCouponCode" :exclude-codes="couponCodes" @update:model-value="addCouponCode" />
        </div>

        <div class="form-section">
          <h3>{{ $t('orderForm.loyaltyPoints.title') }}</h3>
          <BaseInputNumber v-model="redeemPoints" placeholder="0" :min="0" :invalid="!!errors.redeem_points" />
          <small v-if="errors.redeem_points" class="field-error">{{ errors.redeem_points }}</small>
          <p v-if="previewResult" class="empty-hint">
            {{ $t('orderForm.loyaltyPoints.balance', { balance: previewResult.points_redemption.balance }) }}
            <template v-if="previewResult.points_redemption.applied">
              {{ $t('orderForm.loyaltyPoints.applying', { applied: previewResult.points_redemption.applied, amount: previewResult.points_redemption.amount_off }) }}
            </template>
          </p>
          <p v-else class="empty-hint">{{ $t('orderForm.loyaltyPoints.previewHint') }}</p>
        </div>

        <div class="form-actions">
          <BaseButton :label="$t('orderForm.previewButton')" :loading="previewing" outlined @click="runPreview" />
          <BaseButton
            :label="$t('orderForm.createButton')"
            :loading="creating"
            :disabled="!customerExternalId || !lineItems.length || previewStale"
            @click="createOrder"
          />
        </div>
        <p v-if="previewStale && previewResult" class="stale-hint">{{ $t('orderForm.staleHint') }}</p>

        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseMessage v-if="previewError" severity="error" :closable="false">{{ previewError }}</BaseMessage>
        <BaseMessage v-if="createError" severity="error" :closable="false">{{ createError }}</BaseMessage>

        <div v-if="previewResult" class="form-section">
          <h3>{{ $t('orderForm.previewResult.title') }}</h3>
          <p>{{ $t('orderForm.previewResult.totalAmountOff', { amount: previewResult.total_amount_off }) }}</p>
          <p v-if="!previewResult.applicable_discounts.length" class="empty-hint">{{ $t('orderForm.previewResult.noDiscounts') }}</p>
          <ul v-else>
            <li v-for="(d, i) in previewResult.applicable_discounts" :key="i">
              {{ d.name }} ({{ d.kind }}) — {{ d.effect_type }} — {{ describeDiscount(d) }}
            </li>
          </ul>
          <p v-if="previewResult.loyalty_points.total_points">
            {{ $t('orderForm.previewResult.loyaltyPointsEarned', { points: previewResult.loyalty_points.total_points }) }}
            <span v-if="previewResult.loyalty_points.multiplier !== 1" class="coupon-effect">
              {{ $t('orderForm.previewResult.multiplierDetail', { base: previewResult.loyalty_points.base_points, multiplier: previewResult.loyalty_points.multiplier }) }}
            </span>
          </p>
          <p v-if="previewResult.points_redemption.applied">
            {{ $t('orderForm.previewResult.pointsRedeemedSummary', { applied: previewResult.points_redemption.applied, amount: previewResult.points_redemption.amount_off }) }}
          </p>
        </div>
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
.form-section {
  margin: 1rem 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: flex-start;
}

.form-section h3 {
  margin: 0;
  font-size: 0.9375rem;
}

.line-item-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

/* The Base* inputs default to width:100% (right for a vertical form grid) —
   in this horizontal row that reads as flex-basis:auto and each one claims the
   whole row width, wrapping onto its own line. Give them an explicit
   flex-basis so they share the row instead. */
.line-item-row > :nth-child(1) {
  flex: 2 1 8rem;
}

.line-item-row > :nth-child(2),
.line-item-row > :nth-child(3) {
  flex: 1 1 6rem;
}

.line-item-row > :nth-child(4) {
  flex: 0 0 auto;
}

.line-item-row__attrs {
  width: 100%;
  margin-left: 1rem;
}

.coupon-section {
  width: 100%;
  align-items: stretch;
}

.coupon-panel {
  width: 100%;
}

.coupon-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
}

.coupon-effect {
  font-size: 0.875rem;
  color: var(--p-text-muted-color, #6b7280);
}

.coupon-reason {
  font-size: 0.875rem;
  color: var(--p-text-muted-color, #6b7280);
}

.form-actions {
  display: flex;
  gap: 0.75rem;
  margin: 1.5rem 0 0.5rem;
}

.stale-hint {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}

.empty-hint {
  color: var(--p-text-muted-color, #6b7280);
  font-size: 0.875rem;
  margin: 0;
}

.field-error {
  color: var(--p-red-500, #ef4444);
  font-size: 0.8125rem;
}
</style>
