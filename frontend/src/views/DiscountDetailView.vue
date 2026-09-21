<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import EntityLink from '@/components/EntityLink.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseSelectButton from '@/components/base/BaseSelectButton.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseMultiSelect from '@/components/base/BaseMultiSelect.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import ConditionSummary from '@/components/discounts/ConditionSummary.vue'
import KeyValueEditor from '@/components/discounts/KeyValueEditor.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError, apiFileUrl } from '@/lib/api'
import { getDiscount, deleteDiscount } from '@/api/discounts'
import { sanitizeHtml } from '@/lib/sanitizeHtml'
import { listCouponCodes, generateCouponCodes, deleteCouponCode } from '@/api/couponCodes'
import { listCustomers } from '@/api/customers'
import { validateDiscounts } from '@/api/discountRedemption'
import { couponCodeGenerateInputSchema } from '@/models/couponCode'
import { toFieldErrors } from '@/models/formErrors'
import { couponCodeGeneratePayload } from '@/services/couponCodes'
import { attrsToObject, lineItemsToPayload } from '@/services/cartAttrs'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatDateTime } from '@/lib/format'
import { zonedInputToIso } from '@/lib/timezone'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const discount = ref(null)
const loading = ref(false)
const loadError = ref('')

async function loadDiscount() {
  loading.value = true
  loadError.value = ''
  try {
    discount.value = await getDiscount(route.params.id, { token: auth.token, projectId: auth.project?.id })
    if (discount.value.kind === 'coupon') loadCouponCodes()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('discountDetail.loadError')
  } finally {
    loading.value = false
  }
}

// --- coupon codes (bulk / personalized generation) ---

const couponCodes = ref([])
const couponCodesLoading = ref(false)

async function loadCouponCodes() {
  couponCodesLoading.value = true
  try {
    couponCodes.value = await listCouponCodes({ discountId: discount.value.id, perPage: 200, token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('discountDetail.loadCouponCodesError'), detail: e.message, life: 4000 })
  } finally {
    couponCodesLoading.value = false
  }
}

const generateDialogOpen = ref(false)
const topMode = ref('oneoff') // 'oneoff' | 'bulk'
const bulkMode = ref('count') // 'count' | 'customers'
const oneoffCode = ref('')
const oneoffCustomerId = ref(null)
const generateCount = ref(10)
const generateCustomerIds = ref([])
const generatePrefix = ref('')
const generateSuffix = ref('')
const generateMaxRedemptions = ref(1)
const generating = ref(false)
const generateErrors = ref({})

const customers = ref([])
const customerOptions = computed(() => customers.value.map((c) => ({ label: c.external_id, value: c.id })))

async function loadCustomers() {
  customers.value = await listCustomers({ perPage: 500, token: auth.token, projectId: auth.project?.id })
}

function openGenerate() {
  topMode.value = 'oneoff'
  bulkMode.value = 'count'
  oneoffCode.value = ''
  oneoffCustomerId.value = null
  generateCount.value = 10
  generateCustomerIds.value = []
  generatePrefix.value = ''
  generateSuffix.value = ''
  generateMaxRedemptions.value = 1
  generateErrors.value = {}
  generateDialogOpen.value = true
  if (!customers.value.length) loadCustomers()
}

function generatePayload() {
  return couponCodeGeneratePayload({
    mode: topMode.value,
    bulkMode: bulkMode.value,
    code: oneoffCode.value,
    customerId: oneoffCustomerId.value,
    count: generateCount.value,
    customerIds: generateCustomerIds.value,
    prefix: generatePrefix.value,
    suffix: generateSuffix.value,
    maxRedemptions: generateMaxRedemptions.value,
  })
}

async function submitGenerate() {
  generateErrors.value = {}

  const result = couponCodeGenerateInputSchema(t).safeParse(generatePayload())
  if (!result.success) {
    generateErrors.value = toFieldErrors(result.error)
    return
  }

  generating.value = true
  try {
    await generateCouponCodes(discount.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('discountDetail.couponCodesGeneratedToast'), life: 3000 })
    generateDialogOpen.value = false
    await loadCouponCodes()
    discount.value = await getDiscount(discount.value.id, { token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    generateErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('discountDetail.genericError') }
  } finally {
    generating.value = false
  }
}

async function revokeCode(code) {
  try {
    await deleteCouponCode(discount.value.id, code.id, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('discountDetail.codeRevokedToast'), life: 3000 })
    await loadCouponCodes()
    discount.value = await getDiscount(discount.value.id, { token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('discountDetail.revokeCodeError'), detail: e.message, life: 4000 })
  }
}

const couponCodeColumns = computed(() => [
  { field: 'code', header: t('discountDetail.codeColumn'), sortable: true, hideable: false, filter: { type: 'string' } },
  {
    field: 'customer',
    header: t('discountDetail.assignedToColumn'),
    filter: { type: 'string', accessor: (row) => row.customer?.external_id ?? '' },
  },
  { field: 'redemption_count', header: t('discountDetail.redemptionsColumn'), filter: { type: 'number' } },
  { field: 'actions', header: t('discountDetail.actionsColumn'), hideable: false },
])

async function copyCode(code) {
  try {
    await navigator.clipboard.writeText(code)
    toast.add({ severity: 'success', summary: t('discountDetail.copiedToast'), life: 1500 })
  } catch {
    // clipboard access can be denied by the browser — not fatal, just skip the toast
  }
}

const hasUsageLimits = computed(() => {
  if (!discount.value) return false
  return [
    discount.value.max_redemptions,
    discount.value.max_redemptions_per_customer,
    discount.value.max_redemptions_per_day,
    discount.value.max_redemption_amount,
    discount.value.max_redemption_amount_per_day,
    discount.value.max_redemption_amount_per_customer,
  ].some((v) => v != null)
})

function configSummary(effect) {
  const c = effect.config
  if (effect.effect_type === 'percentage_off') return t('discountDetail.percentageOff', { percentage: formatNumber(c.percentage) })
  if (effect.effect_type === 'fixed_amount_off') return t('discountDetail.fixedAmountOff', { amount: formatNumber(c.amount), currency: c.currency })
  if (effect.effect_type === 'free_item') {
    return c.repeatable
      ? t('discountDetail.freeItemEffectRepeatable', { buyQuantity: c.buy_quantity, getQuantity: c.get_quantity })
      : t('discountDetail.freeItemEffect', { buyQuantity: c.buy_quantity, getQuantity: c.get_quantity })
  }
  if (effect.effect_type === 'points_per_currency') return t('discountDetail.pointsPerCurrency', { rate: c.rate })
  if (effect.effect_type === 'points_flat') return t('discountDetail.pointsFlat', { points: c.points })
  if (effect.effect_type === 'points_per_item') return t('discountDetail.pointsPerItem', { pointsPerItem: c.points_per_item })
  if (effect.effect_type === 'points_multiplier') return t('discountDetail.pointsMultiplierSuffix', { multiplier: c.multiplier })
  return ''
}

function editDiscount() {
  router.push({ name: 'discount-edit', params: { id: route.params.id } })
}

function viewCampaign() {
  router.push({ name: 'campaign-show', params: { id: discount.value.campaign.id } })
}

// --- delete (hard, permanent — enabled/disabled is the reversible everyday toggle) ---

const deleteDialogOpen = ref(false)
const deleting = ref(false)

async function confirmDelete() {
  deleting.value = true
  try {
    await deleteDiscount(discount.value.id, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('discountDetail.discountDeletedToast'), life: 3000 })
    router.push({ name: 'campaign-show', params: { id: discount.value.campaign.id } })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('discountDetail.deleteDiscountError'), detail: e.message, life: 4000 })
  } finally {
    deleting.value = false
    deleteDialogOpen.value = false
  }
}

// --- validation tester ---

function defaultLineItem() {
  return { sku: '', quantity: 1, unit_price: 0, attrs: [] }
}

const lineItems = ref([defaultLineItem()])
const cartAttrs = ref([])
const customerExternalId = ref('test-customer')
const customerAttrs = ref([])
const couponCode = ref('')
const asOf = ref('')

function addLineItem() {
  lineItems.value = [...lineItems.value, defaultLineItem()]
}
function removeLineItem(index) {
  lineItems.value = lineItems.value.filter((_, i) => i !== index)
}

function buildPayload() {
  return {
    cart: attrsToObject(cartAttrs.value),
    line_items: lineItemsToPayload(lineItems.value),
    customer: { external_id: customerExternalId.value, ...attrsToObject(customerAttrs.value) },
    coupon_codes: couponCode.value ? [couponCode.value] : [],
    as_of: zonedInputToIso(asOf.value, auth.project?.timezone) ?? undefined,
  }
}

const testing = ref(false)
const testError = ref('')
const testResult = ref(null)

async function runTest() {
  testing.value = true
  testError.value = ''
  testResult.value = null
  try {
    testResult.value = await validateDiscounts(buildPayload(), { token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    testError.value = e instanceof ApiError ? e.message : t('discountDetail.genericError')
  } finally {
    testing.value = false
  }
}

const matchingResult = computed(() => {
  if (discount.value?.kind === 'loyalty') {
    return testResult.value?.loyalty_points?.breakdown?.find((d) => d.discount_id === discount.value?.id)
  }
  return testResult.value?.applicable_discounts?.find((d) => d.discount_id === discount.value?.id)
})

onMounted(loadDiscount)
</script>

<template>
  <AppShell>
    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <template v-if="discount">
      <PageHeader :crumbs="[{ label: discount.campaign.name, to: { name: 'campaign-show', params: { id: discount.campaign.id } } }]">
        <template #title>
          <h2>{{ discount.name }}</h2>
          <BaseTag :value="discount.kind" />
          <BaseTag v-if="discount.stackable" severity="info" :value="$t('discountDetail.stackableTag')" />
          <BaseTag v-if="!discount.enabled" severity="secondary" :value="$t('discountDetail.disabledTag')" />
        </template>
        <template #actions>
          <BaseButton :label="$t('discountDetail.editButton')" @click="editDiscount" />
          <BaseButton text severity="danger" :label="$t('discountDetail.deleteButton')" @click="deleteDialogOpen = true" />
        </template>
      </PageHeader>

      <BaseDialog v-model:visible="deleteDialogOpen" modal :header="$t('discountDetail.deleteDialogHeader')" :style="{ width: '26rem' }">
        <p>
          {{ $t('discountDetail.deleteDialogBodyBefore') }} <strong>{{ discount.name }}</strong> {{ $t('discountDetail.deleteDialogBodyMiddle') }} <strong>{{ $t('discountDetail.enabledWord') }}</strong> {{ $t('discountDetail.deleteDialogBodyAfter') }}
        </p>
        <div class="delete-dialog__actions">
          <BaseButton text :label="$t('discountDetail.cancelButton')" @click="deleteDialogOpen = false" />
          <BaseButton severity="danger" :label="$t('discountDetail.deletePermanentlyButton')" :loading="deleting" @click="confirmDelete" />
        </div>
      </BaseDialog>

      <div class="detail-grid">
        <BaseCard>
          <template #title>{{ $t('discountDetail.basicsTitle') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('discountDetail.keyLabel') }}</dt>
              <dd>{{ discount.key }}</dd>
              <dt>{{ $t('discountDetail.campaignLabel') }}</dt>
              <dd>
                <EntityLink @click="viewCampaign">{{ discount.campaign.name }}</EntityLink>
                <BaseTag
                  class="campaign-status"
                  :severity="discount.campaign.active ? 'success' : 'danger'"
                  :value="discount.campaign.active ? $t('discountDetail.statusActive') : $t('discountDetail.statusInactive')"
                />
              </dd>
              <dt>{{ $t('discountDetail.createdLabel') }}</dt>
              <dd>{{ formatDateTime(discount.created_at, auth.project?.timezone) }}</dd>
            </dl>
          </template>
        </BaseCard>

        <BaseCard v-if="discount.kind === 'promotion'">
          <template #title>{{ $t('discountDetail.promotionTitle') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('discountDetail.activeFromLabel') }}</dt>
              <dd>{{ formatDateTime(discount.promotion.active_from, auth.project?.timezone) }}</dd>
              <dt>{{ $t('discountDetail.activeUntilLabel') }}</dt>
              <dd>{{ discount.promotion.active_until ? formatDateTime(discount.promotion.active_until, auth.project?.timezone) : $t('discountDetail.noEndDate') }}</dd>
            </dl>
          </template>
        </BaseCard>

        <BaseCard v-else-if="discount.kind === 'coupon'">
          <template #title>{{ $t('discountDetail.couponTitle') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('discountDetail.codesLabel') }}</dt>
              <dd>{{ $t('discountDetail.codesAvailableOfTotal', { available: discount.coupon_code_stats.available, total: discount.coupon_code_stats.total }) }}</dd>
              <dt>{{ $t('discountDetail.validLabel') }}</dt>
              <dd>
                {{ discount.coupon.valid_from ? formatDateTime(discount.coupon.valid_from, auth.project?.timezone) : $t('discountDetail.anytime') }}
                &ndash;
                {{ discount.coupon.valid_until ? formatDateTime(discount.coupon.valid_until, auth.project?.timezone) : $t('discountDetail.noEnd') }}
              </dd>
            </dl>
          </template>
        </BaseCard>

        <BaseCard v-else-if="discount.kind === 'loyalty'">
          <template #title>{{ $t('discountDetail.loyaltyTitle') }}</template>
          <template #content>
            <dl class="details">
              <dt>{{ $t('discountDetail.activeFromLabel') }}</dt>
              <dd>{{ formatDateTime(discount.loyalty.active_from, auth.project?.timezone) }}</dd>
              <dt>{{ $t('discountDetail.activeUntilLabel') }}</dt>
              <dd>{{ discount.loyalty.active_until ? formatDateTime(discount.loyalty.active_until, auth.project?.timezone) : $t('discountDetail.noEndDate') }}</dd>
            </dl>
          </template>
        </BaseCard>

        <BaseCard v-if="discount.kind === 'coupon' && (discount.coupon.design_image_url || discount.coupon.design_html)">
          <template #title>{{ $t('discountDetail.designTitle') }}</template>
          <template #content>
            <img
              v-if="discount.coupon.design_image_url"
              :src="apiFileUrl(discount.coupon.design_image_url)"
              :alt="$t('discountDetail.designImageAlt')"
              class="design-image-preview"
            />
            <!-- eslint-disable-next-line vue/no-v-html -- the one deliberate v-html in this app; sanitizeHtml() is the only thing ever passed to it -->
            <div v-if="discount.coupon.design_html" class="design-preview" v-html="sanitizeHtml(discount.coupon.design_html)" />
          </template>
        </BaseCard>

        <BaseCard v-if="hasUsageLimits">
          <template #title>{{ $t('discountDetail.usageLimitsTitle') }}</template>
          <template #content>
            <dl class="details">
              <template v-if="discount.max_redemptions != null">
                <dt>{{ $t('discountDetail.maxRedemptions') }}</dt>
                <dd>{{ formatNumber(discount.max_redemptions) }}</dd>
              </template>
              <template v-if="discount.max_redemptions_per_customer != null">
                <dt>{{ $t('discountDetail.maxRedemptionsPerCustomer') }}</dt>
                <dd>{{ formatNumber(discount.max_redemptions_per_customer) }}</dd>
              </template>
              <template v-if="discount.max_redemptions_per_day != null">
                <dt>{{ $t('discountDetail.maxRedemptionsPerDay') }}</dt>
                <dd>{{ formatNumber(discount.max_redemptions_per_day) }}</dd>
              </template>
              <template v-if="discount.max_redemption_amount != null">
                <dt>{{ $t('discountDetail.maxTotalRedeemed') }}</dt>
                <dd>{{ formatNumber(discount.max_redemption_amount) }}</dd>
              </template>
              <template v-if="discount.max_redemption_amount_per_day != null">
                <dt>{{ $t('discountDetail.maxRedeemedPerDay') }}</dt>
                <dd>{{ formatNumber(discount.max_redemption_amount_per_day) }}</dd>
              </template>
              <template v-if="discount.max_redemption_amount_per_customer != null">
                <dt>{{ $t('discountDetail.maxRedeemedPerCustomer') }}</dt>
                <dd>{{ formatNumber(discount.max_redemption_amount_per_customer) }}</dd>
              </template>
            </dl>
          </template>
        </BaseCard>

        <BaseCard>
          <template #title>{{ $t('discountDetail.eligibilityTitle') }}</template>
          <template #content>
            <ConditionSummary :node="discount.eligibility_condition" />
          </template>
        </BaseCard>

        <BaseCard>
          <template #title>{{ $t('discountDetail.effectsTitle') }}</template>
          <template #content>
            <p v-if="!discount.effects.length" class="empty-hint">{{ $t('discountDetail.noEffects') }}</p>
            <div v-for="effect in discount.effects" :key="effect.id" class="effect-summary">
              <div class="effect-summary__header">
                <BaseTag :value="effect.effect_type" />
                <BaseTag severity="secondary" :value="effect.scope" />
                <span>{{ configSummary(effect) }}</span>
              </div>
              <div v-if="effect.scope === 'line_item'" class="effect-summary__condition">
                {{ $t('discountDetail.appliesToLineItemsWhere') }} <ConditionSummary :node="effect.target_condition" />
              </div>
              <div v-if="effect.effect_type === 'free_item'" class="effect-summary__condition">
                {{ $t('discountDetail.buyLabel') }} <ConditionSummary :node="effect.config.buy_condition" /><br />
                {{ $t('discountDetail.getLabel') }} <ConditionSummary :node="effect.config.get_condition" />
              </div>
            </div>
          </template>
        </BaseCard>
      </div>

      <BaseCard v-if="discount.kind === 'coupon'" class="section-card">
        <template #title>
          <div class="card-title-row">
            <span>{{ $t('discountDetail.couponCodesTitle') }}</span>
            <BaseButton size="small" :label="$t('discountDetail.generateCodesButton')" @click="openGenerate" />
          </div>
        </template>
        <template #content>
          <BaseTable :data="couponCodes" :columns="couponCodeColumns" :loading="couponCodesLoading" row-key="id" @refresh="loadCouponCodes">
            <template #cell-code="{ data }">
              <EntityLink @click="copyCode(data.code)"><span class="coupon-code">{{ data.code }}</span></EntityLink>
            </template>
            <template #cell-customer="{ data }">{{ data.customer ? data.customer.external_id : $t('discountDetail.anyone') }}</template>
            <template #cell-redemption_count="{ data }">{{ $t('discountDetail.redemptionsOfMax', { count: formatNumber(data.redemption_count), max: formatNumber(data.max_redemptions) }) }}</template>
            <template #cell-actions="{ data }">
              <BaseButton
                v-if="data.redemption_count === 0"
                text
                size="small"
                severity="danger"
                :label="$t('discountDetail.revokeButton')"
                @click="revokeCode(data)"
              />
            </template>
            <template #empty>{{ $t('discountDetail.noCodesHint') }}</template>
          </BaseTable>
        </template>
      </BaseCard>

      <BaseDialog v-model:visible="generateDialogOpen" modal :header="$t('discountDetail.addCodesDialogHeader')" :style="{ width: '28rem' }">
        <div class="dialog-form">
          <BaseSelectButton
            v-model="topMode"
            :options="[
              { label: $t('discountDetail.oneoffOption'), value: 'oneoff' },
              { label: $t('discountDetail.bulkOption'), value: 'bulk' },
            ]"
            option-label="label"
            option-value="value"
          />

          <template v-if="topMode === 'oneoff'">
            <label>{{ $t('discountDetail.codeLabel') }}</label>
            <BaseInputText v-model="oneoffCode" :placeholder="$t('discountDetail.codePlaceholder')" />
            <label>{{ $t('discountDetail.assignCustomerLabel') }}</label>
            <BaseSelect v-model="oneoffCustomerId" :options="customerOptions" option-label="label" option-value="value" filter show-clear :placeholder="$t('discountDetail.anyonePlaceholder')" />
            <label>{{ $t('discountDetail.maxRedemptionsLabel') }}</label>
            <BaseInputNumber v-model="generateMaxRedemptions" :min="1" />
            <p class="usage-limits-hint">
              {{ $t('discountDetail.singleUseHint') }}
            </p>
          </template>

          <template v-else>
            <BaseSelectButton
              v-model="bulkMode"
              :options="[
                { label: $t('discountDetail.anonymousOption'), value: 'count' },
                { label: $t('discountDetail.personalizedOption'), value: 'customers' },
              ]"
              option-label="label"
              option-value="value"
            />

            <template v-if="bulkMode === 'count'">
              <label>{{ $t('discountDetail.howManyCodesLabel') }}</label>
              <BaseInputNumber v-model="generateCount" :min="1" :max="5000" :invalid="!!generateErrors.count" />
              <small v-if="generateErrors.count" class="text-danger text-[0.8125rem]">{{ generateErrors.count }}</small>
            </template>
            <template v-else>
              <label>{{ $t('discountDetail.customersOneCodeEachLabel') }}</label>
              <BaseMultiSelect v-model="generateCustomerIds" :options="customerOptions" option-label="label" option-value="value" filter />
            </template>

            <label>{{ $t('discountDetail.prefixLabel') }}</label>
            <BaseInputText v-model="generatePrefix" :placeholder="$t('discountDetail.prefixPlaceholder')" />
            <label>{{ $t('discountDetail.suffixLabel') }}</label>
            <BaseInputText v-model="generateSuffix" :placeholder="$t('discountDetail.suffixPlaceholder')" />
            <label>{{ $t('discountDetail.maxRedemptionsPerCodeLabel') }}</label>
            <BaseInputNumber v-model="generateMaxRedemptions" :min="1" />
          </template>

          <BaseMessage v-if="generateErrors._root" severity="error" :closable="false">{{ generateErrors._root }}</BaseMessage>
          <BaseButton :label="$t('discountDetail.addButton')" :loading="generating" @click="submitGenerate" />
        </div>
      </BaseDialog>

      <BaseCard class="tester-card">
        <template #title>{{ $t('discountDetail.testValidationTitle') }}</template>
        <template #content>
          <p class="tester-hint">
            {{ $t('discountDetail.testerHintBefore') }}
            <code>/api/v1/discounts/validate</code> {{ $t('discountDetail.testerHintAfter') }}
          </p>

          <div class="tester-section">
            <h3>{{ $t('discountDetail.lineItemsTitle') }}</h3>
            <div v-for="(li, i) in lineItems" :key="i" class="line-item-row">
              <BaseInputText v-model="li.sku" :placeholder="$t('discountDetail.skuPlaceholder')" />
              <BaseInputNumber v-model="li.quantity" :placeholder="$t('discountDetail.quantityPlaceholder')" :min="1" />
              <BaseInputNumber v-model="li.unit_price" :placeholder="$t('discountDetail.unitPricePlaceholder')" :min="0" :min-fraction-digits="2" />
              <BaseButton text severity="danger" icon="pi pi-times" @click="removeLineItem(i)" />
              <KeyValueEditor v-model="li.attrs" entity="line_item" class="line-item-row__attrs" />
            </div>
            <BaseButton size="small" text :label="$t('discountDetail.addLineItemButton')" @click="addLineItem" />
          </div>

          <div class="tester-section">
            <h3>{{ $t('discountDetail.cartAttributesTitle') }}</h3>
            <KeyValueEditor v-model="cartAttrs" entity="cart" />
          </div>

          <div class="tester-section">
            <h3>{{ $t('discountDetail.customerTitle') }}</h3>
            <label>{{ $t('discountDetail.externalIdLabel') }}</label>
            <BaseInputText v-model="customerExternalId" />
            <KeyValueEditor v-model="customerAttrs" entity="customer" />
          </div>

          <div class="tester-section">
            <h3>{{ $t('discountDetail.couponCodeTitle') }}</h3>
            <BaseInputText v-model="couponCode" :placeholder="$t('discountDetail.optionalPlaceholder')" />
          </div>

          <div class="tester-section">
            <h3>{{ $t('discountDetail.testAsOfTitle') }}</h3>
            <BaseInputText v-model="asOf" type="datetime-local" />
            <p class="tester-hint">{{ $t('discountDetail.testAsOfHint') }}</p>
          </div>

          <BaseButton :label="$t('discountDetail.runTestButton')" :loading="testing" @click="runTest" />

          <BaseMessage v-if="testError" severity="error" :closable="false">{{ testError }}</BaseMessage>

          <template v-if="testResult">
            <BaseMessage :severity="matchingResult ? 'success' : 'warn'" :closable="false">
              <template v-if="matchingResult">
                {{ $t('discountDetail.appliesMessage') }}
                <template v-if="matchingResult.amount_off != null">{{ $t('discountDetail.amountOffText', { amount: formatNumber(matchingResult.amount_off) }) }}</template>
                <template v-else-if="matchingResult.free_items">
                  {{ $t('discountDetail.appliesFreeItems', { items: matchingResult.free_items.map((f) => `${f.quantity}x ${f.sku}`).join(', ') }) }}
                </template>
                <template v-else-if="matchingResult.points != null">{{ $t('discountDetail.pointsEarnedSuffix', { points: matchingResult.points }) }}</template>
                <template v-else-if="matchingResult.multiplier != null">{{ $t('discountDetail.pointsMultiplierSuffix', { multiplier: matchingResult.multiplier }) }}</template>
              </template>
              <template v-else>{{ $t('discountDetail.doesNotApplyMessage') }}</template>
            </BaseMessage>

            <div class="tester-section">
              <h3>{{ $t('discountDetail.fullResultTitle') }}</h3>
              <p>{{ $t('discountDetail.totalAmountOffLabel', { amount: formatNumber(testResult.total_amount_off) }) }}</p>
              <p v-for="(c, i) in testResult.coupons" :key="i">
                {{ $t('discountDetail.couponLine', { code: c.code, status: c.valid ? $t('discountDetail.validStatus') : $t('discountDetail.invalidStatus', { reason: c.reason }) }) }}
              </p>
              <ul>
                <li v-for="(d, i) in testResult.applicable_discounts" :key="i">
                  {{ d.name }} ({{ d.kind }}) — {{ d.effect_type }} —
                  <template v-if="d.amount_off != null">{{ $t('discountDetail.amountOffText', { amount: formatNumber(d.amount_off) }) }}</template>
                  <template v-else-if="d.free_items">{{ $t('discountDetail.freeText', { items: d.free_items.map((f) => `${f.quantity}x ${f.sku}`).join(', ') }) }}</template>
                </li>
              </ul>
              <p v-if="testResult.loyalty_points.total_points">
                {{ $t('discountDetail.loyaltyPointsEarned', { points: testResult.loyalty_points.total_points }) }}
                <span v-if="testResult.loyalty_points.multiplier !== 1">
                  {{ $t('discountDetail.loyaltyPointsBreakdown', { base: testResult.loyalty_points.base_points, multiplier: testResult.loyalty_points.multiplier }) }}
                </span>
              </p>
            </div>
          </template>
        </template>
      </BaseCard>
    </template>
  </AppShell>
</template>

<style scoped>
.delete-dialog__actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1rem;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.section-card {
  margin-bottom: 1.5rem;
}

.design-image-preview {
  width: 10rem;
  height: 10rem;
  object-fit: cover;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  margin-bottom: 0.5rem;
}

.design-preview {
  padding: 0.75rem 1rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
}

.coupon-code {
  font-family: monospace;
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

.campaign-status {
  margin-left: 0.5rem;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0;
}

.effect-summary {
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 0.75rem;
  margin-bottom: 0.75rem;
}

.effect-summary:last-child {
  margin-bottom: 0;
}

.effect-summary__header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.effect-summary__condition {
  margin-top: 0.5rem;
  font-size: 0.875rem;
}

.tester-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.tester-section {
  margin: 1rem 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: flex-start;
}

.tester-section h3 {
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
</style>
