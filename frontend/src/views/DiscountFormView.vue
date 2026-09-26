<script setup>
import { computed, reactive, ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseTextarea from '@/components/base/BaseTextarea.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'
import BaseSelectButton from '@/components/base/BaseSelectButton.vue'
import BaseMultiSelect from '@/components/base/BaseMultiSelect.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import ConditionTreeEditor from '@/components/discounts/ConditionTreeEditor.vue'
import EffectEditor from '@/components/discounts/EffectEditor.vue'
import DiscountSummarySidebar from '@/components/discounts/DiscountSummarySidebar.vue'
import UnsavedChangesDialog from '@/components/UnsavedChangesDialog.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError, apiFileUrl } from '@/lib/api'
import {
  getDiscount,
  createDiscount,
  updateDiscount,
  listDiscounts,
  addCompatibleDiscount,
  removeCompatibleDiscount,
  uploadCouponDesignImage,
} from '@/api/discounts'
import { listCampaigns } from '@/api/campaigns'
import { listCustomers } from '@/api/customers'
import { discountInputSchema } from '@/models/discount'
import { toFieldErrors } from '@/models/formErrors'
import { couponCodeGeneratePayload } from '@/services/couponCodes'
import { useBaseToast } from '@/composables/useBaseToast'
import { useUnsavedChangesGuard } from '@/composables/useUnsavedChangesGuard'
import { sanitizeHtml } from '@/lib/sanitizeHtml'
import { isoToZonedInput, zonedInputToIso } from '@/lib/timezone'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const discountId = computed(() => route.params.id || null)
const isEdit = computed(() => !!discountId.value)

const KIND_OPTIONS = computed(() => [
  { label: t('discountForm.kindPromotion'), value: 'promotion' },
  { label: t('discountForm.kindCoupon'), value: 'coupon' },
  { label: t('discountForm.kindLoyalty'), value: 'loyalty' },
])

const loading = ref(false)
const saving = ref(false)
const loadError = ref('')
const errors = ref({})

// Which summary-sidebar section to subtly highlight, driven by plain focus
// bubbling from each major card — purely presentational, no interaction model.
const activeSection = ref(null)

// The summary sidebar only knows how to summarize coupon/promotion discounts
// (see DiscountSummarySidebar.vue) — loyalty's points-based effects aren't
// covered, so loyalty keeps the original single-column layout.
const showSummary = computed(() => ['coupon', 'promotion'].includes(form.kind))

const campaigns = ref([])
const campaignOptions = computed(() => campaigns.value.map((c) => ({ label: c.name, value: c.id })))
const currentCampaign = computed(() => campaigns.value.find((c) => c.id === form.campaign_id))

async function loadCampaigns() {
  campaigns.value = await listCampaigns({ perPage: 500, token: auth.token, projectId: auth.project?.id })
}

// --- compatible discounts (stacking exceptions) ---

const allDiscounts = ref([])
const discountOptions = computed(() =>
  allDiscounts.value.filter((d) => d.id !== discountId.value).map((d) => ({ label: `${d.name} (${d.kind})`, value: d.id }))
)
const compatibleDiscountIds = ref([])
const savingCompatibility = ref(false)

async function loadAllDiscounts() {
  allDiscounts.value = await listDiscounts({ perPage: 500, token: auth.token, projectId: auth.project?.id })
}

async function updateCompatibleDiscounts(newIds) {
  const previousIds = compatibleDiscountIds.value
  const added = newIds.filter((id) => !previousIds.includes(id))
  const removed = previousIds.filter((id) => !newIds.includes(id))
  compatibleDiscountIds.value = newIds
  savingCompatibility.value = true
  try {
    for (const id of added) {
      await addCompatibleDiscount(discountId.value, id, { token: auth.token, projectId: auth.project?.id })
    }
    for (const id of removed) {
      await removeCompatibleDiscount(discountId.value, id, { token: auth.token, projectId: auth.project?.id })
    }
  } catch (e) {
    compatibleDiscountIds.value = previousIds
    toast.add({ severity: 'error', summary: t('discountForm.compatibilityError'), detail: e.message, life: 4000 })
  } finally {
    savingCompatibility.value = false
  }
}

// --- coupon codes (only offered at creation — after that, use the discount's own
// Coupon codes section, which supports the same one-off/bulk modes) ---

const customers = ref([])
const customerOptions = computed(() => customers.value.map((c) => ({ label: c.external_id, value: c.id })))
async function loadCustomers() {
  customers.value = await listCustomers({ perPage: 500, token: auth.token, projectId: auth.project?.id })
}

const couponCodeMode = ref('oneoff') // 'oneoff' | 'bulk'
const couponBulkMode = ref('count') // 'count' | 'customers'

function couponCodePayload() {
  // Coupon codes are optional at creation time — an empty one-off code means
  // "skip code generation entirely," unlike the detail page's dialog, which is
  // only ever opened to intentionally generate something.
  if (couponCodeMode.value === 'oneoff' && !form.couponCode.code) return {}

  return couponCodeGeneratePayload({
    mode: couponCodeMode.value,
    bulkMode: couponBulkMode.value,
    code: form.couponCode.code,
    customerId: form.couponCode.customerId,
    count: form.couponCode.count,
    customerIds: form.couponCode.customerIds,
    prefix: form.couponCode.prefix,
    suffix: form.couponCode.suffix,
    maxRedemptions: form.couponCode.maxRedemptions,
  })
}

const form = reactive({
  kind: 'promotion',
  campaign_id: route.query.campaign_id || null,
  key: '',
  name: '',
  stackable: false,
  refundable: true,
  enabled: true,
  eligibility_condition: null,
  max_redemptions: null,
  max_redemptions_per_customer: null,
  max_redemptions_per_day: null,
  max_redemption_amount: null,
  max_redemption_amount_per_day: null,
  max_redemption_amount_per_customer: null,
  promotion: { active_from: '', active_until: '' },
  coupon: {
    issued_from: '',
    issued_until: '',
    valid_from: '',
    valid_until: '',
    design_html: '',
  },
  loyalty: { active_from: '', active_until: '', points_expire_after_days: null },
  couponCode: { code: '', customerId: null, count: 10, customerIds: [], prefix: '', suffix: '', maxRedemptions: 1 },
  effects: [],
})

// Snapshotted right after the form reflects "what's actually saved" (at
// declaration for a new discount, after load() for an existing one).
const initialSnapshot = ref(JSON.stringify(form))

function isDirty() {
  return JSON.stringify(form) !== initialSnapshot.value
}

const { showDialog: showUnsavedDialog, confirmLeave, cancelLeave, bypassOnce } = useUnsavedChangesGuard(isDirty)

function defaultEffect() {
  if (form.kind === 'loyalty') {
    return { effect_type: 'points_per_currency', scope: 'cart', target_condition: null, config: { rate: 1 } }
  }
  return { effect_type: 'percentage_off', scope: 'cart', target_condition: null, config: { percentage: 10 } }
}

function addEffect() {
  form.effects.push(defaultEffect())
}
function removeEffect(i) {
  form.effects.splice(i, 1)
}

// Coupon design image — same upload-after-save pattern as GiftShopItemFormView.vue's
// photo (a separate multipart request, not part of the main JSON payload).
const existingDesignImageUrl = ref(null)
const designImageFile = ref(null)
const designImagePreviewUrl = ref(null)

function onDesignImageSelected(event) {
  const file = event.target.files?.[0]
  if (!file) return
  designImageFile.value = file
  if (designImagePreviewUrl.value) URL.revokeObjectURL(designImagePreviewUrl.value)
  designImagePreviewUrl.value = URL.createObjectURL(file)
}

onBeforeUnmount(() => {
  if (designImagePreviewUrl.value) URL.revokeObjectURL(designImagePreviewUrl.value)
})

async function uploadDesignImageIfSelected(id) {
  if (!designImageFile.value) return
  await uploadCouponDesignImage(id, designImageFile.value, { token: auth.token, projectId: auth.project?.id })
}

async function load() {
  loading.value = true
  try {
    const data = await getDiscount(discountId.value, { token: auth.token, projectId: auth.project?.id })
    form.kind = data.kind
    form.campaign_id = data.campaign.id
    form.key = data.key
    form.name = data.name
    form.stackable = data.stackable
    form.refundable = data.refundable
    form.enabled = data.enabled
    form.eligibility_condition = data.eligibility_condition && Object.keys(data.eligibility_condition).length ? data.eligibility_condition : null
    form.max_redemptions = data.max_redemptions
    form.max_redemptions_per_customer = data.max_redemptions_per_customer
    form.max_redemptions_per_day = data.max_redemptions_per_day
    form.max_redemption_amount = data.max_redemption_amount
    form.max_redemption_amount_per_day = data.max_redemption_amount_per_day
    form.max_redemption_amount_per_customer = data.max_redemption_amount_per_customer

    if (data.promotion) {
      form.promotion = {
        active_from: isoToZonedInput(data.promotion.active_from, auth.project?.timezone),
        active_until: isoToZonedInput(data.promotion.active_until, auth.project?.timezone),
      }
    }
    if (data.coupon) {
      form.coupon = {
        issued_from: isoToZonedInput(data.coupon.issued_from, auth.project?.timezone),
        issued_until: isoToZonedInput(data.coupon.issued_until, auth.project?.timezone),
        valid_from: isoToZonedInput(data.coupon.valid_from, auth.project?.timezone),
        valid_until: isoToZonedInput(data.coupon.valid_until, auth.project?.timezone),
        design_html: data.coupon.design_html || '',
      }
      existingDesignImageUrl.value = data.coupon.design_image_url
    }
    if (data.loyalty) {
      form.loyalty = {
        active_from: isoToZonedInput(data.loyalty.active_from, auth.project?.timezone),
        active_until: isoToZonedInput(data.loyalty.active_until, auth.project?.timezone),
        points_expire_after_days: data.loyalty.points_expire_after_days,
      }
    }

    form.effects = (data.effects || []).map((e) => ({
      effect_type: e.effect_type,
      scope: e.scope,
      target_condition: e.target_condition && Object.keys(e.target_condition).length ? e.target_condition : null,
      config: e.config,
    }))

    compatibleDiscountIds.value = (data.compatible_discounts || []).map((d) => d.id)
    initialSnapshot.value = JSON.stringify(form)
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('discountForm.loadError')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadCampaigns()
  if (isEdit.value) {
    load()
    loadAllDiscounts()
  } else {
    loadCustomers()
  }
})

// `kind` is always included so discountInputSchema(t) can pick the right union
// branch for validation, even on update where it isn't sent to the server (the
// update endpoint dispatches on the existing discount's kind, not the body) — see
// submit(), which strips it back out of the request body when isEdit.
function buildPayload() {
  const payload = {
    kind: form.kind,
    key: form.key || null,
    name: form.name,
    campaign_id: form.campaign_id,
    stackable: form.stackable,
    refundable: form.refundable,
    enabled: form.enabled,
    eligibility_condition: form.eligibility_condition,
    effects: form.effects,
    max_redemptions: form.max_redemptions,
    max_redemptions_per_customer: form.max_redemptions_per_customer,
    max_redemptions_per_day: form.max_redemptions_per_day,
    max_redemption_amount: form.max_redemption_amount,
    max_redemption_amount_per_day: form.max_redemption_amount_per_day,
    max_redemption_amount_per_customer: form.max_redemption_amount_per_customer,
  }

  if (form.kind === 'promotion') {
    payload.promotion = {
      active_from: zonedInputToIso(form.promotion.active_from, auth.project?.timezone),
      active_until: zonedInputToIso(form.promotion.active_until, auth.project?.timezone),
    }
  } else if (form.kind === 'coupon') {
    payload.coupon = {
      issued_from: zonedInputToIso(form.coupon.issued_from, auth.project?.timezone),
      issued_until: zonedInputToIso(form.coupon.issued_until, auth.project?.timezone),
      valid_from: zonedInputToIso(form.coupon.valid_from, auth.project?.timezone),
      valid_until: zonedInputToIso(form.coupon.valid_until, auth.project?.timezone),
      design_html: form.coupon.design_html || null,
      ...(isEdit.value ? {} : couponCodePayload()),
    }
  } else {
    payload.loyalty = {
      active_from: zonedInputToIso(form.loyalty.active_from, auth.project?.timezone),
      active_until: zonedInputToIso(form.loyalty.active_until, auth.project?.timezone),
      points_expire_after_days: form.loyalty.points_expire_after_days || null,
    }
  }
  return payload
}

// Reached from a campaign's own "Edit campaign" screen (its Discounts table
// passes `return_to=campaign-edit` when linking here) means both cancelling
// and saving should hand control back to that screen — not the discount's
// own detail page, which is where every other entry point into this form
// sends you.
function returnRoute() {
  if (route.query.return_to === 'campaign-edit' && form.campaign_id) {
    return { name: 'campaign-edit', params: { id: form.campaign_id } }
  }
  return null
}

async function submit() {
  errors.value = {}

  const payload = buildPayload()
  const result = discountInputSchema(t, { isEdit: isEdit.value }).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  const body = { ...result.data }
  if (isEdit.value) delete body.kind

  saving.value = true
  try {
    if (isEdit.value) {
      await updateDiscount(discountId.value, body, { token: auth.token, projectId: auth.project?.id })
      await uploadDesignImageIfSelected(discountId.value)
      toast.add({ severity: 'success', summary: t('discountForm.updatedToast'), life: 3000 })
      bypassOnce()
      router.push(returnRoute() || { name: 'discount-show', params: { id: discountId.value } })
    } else {
      const discount = await createDiscount(body, { token: auth.token, projectId: auth.project?.id })
      await uploadDesignImageIfSelected(discount.id)
      toast.add({ severity: 'success', summary: t('discountForm.createdToast'), life: 3000 })
      bypassOnce()
      router.push(returnRoute() || { name: 'discount-show', params: { id: discount.id } })
    }
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('discountForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
  if (returnRoute()) {
    router.push(returnRoute())
  } else if (form.campaign_id) {
    router.push({ name: 'campaign-show', params: { id: form.campaign_id } })
  } else {
    router.push({ name: 'campaigns' })
  }
}
</script>

<template>
  <AppShell>
    <PageHeader :crumbs="currentCampaign ? [{ label: currentCampaign.name, to: { name: 'campaign-show', params: { id: currentCampaign.id } } }] : []">
      <template #title>
        <h2>{{ isEdit ? $t('discountForm.editTitle') : $t('discountForm.newTitle') }}</h2>
      </template>
    </PageHeader>

    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <div class="discount-form-layout" :class="{ 'discount-form-layout--with-summary': showSummary }">
      <form class="discount-form discount-form-main" @submit.prevent="submit">
        <BaseCard @focusin="activeSection = 'coupon'">
          <template #title>{{ $t('discountForm.basicsTitle') }}</template>
          <template #content>
            <div class="field-grid">
              <div class="field">
                <label for="kind">{{ $t('discountForm.kindLabel') }}</label>
                <BaseSelect id="kind" v-model="form.kind" :disabled="isEdit" :options="KIND_OPTIONS" option-label="label" option-value="value" />
              </div>
              <div class="field">
                <label for="campaign_id">{{ $t('discountForm.campaignLabel') }}</label>
                <BaseSelect id="campaign_id" v-model="form.campaign_id" :options="campaignOptions" option-label="label" option-value="value" filter :invalid="!!errors.campaign_id" />
                <small v-if="errors.campaign_id" class="text-danger text-[0.8125rem]">{{ errors.campaign_id }}</small>
              </div>
              <div class="field">
                <label for="key">{{ isEdit ? $t('discountForm.keyLabel') : $t('discountForm.keyLabelOptional') }}</label>
                <BaseInputText id="key" v-model="form.key" :placeholder="isEdit ? '' : $t('discountForm.keyPlaceholder')" :invalid="!!errors.key" />
                <small v-if="errors.key" class="text-danger text-[0.8125rem]">{{ errors.key }}</small>
              </div>
              <div class="field">
                <label for="name">{{ $t('discountForm.nameLabel') }}</label>
                <BaseInputText id="name" v-model="form.name" :invalid="!!errors.name" />
                <small v-if="errors.name" class="text-danger text-[0.8125rem]">{{ errors.name }}</small>
              </div>
              <div class="field field--switch">
                <label for="stackable">{{ $t('discountForm.stackableLabel') }}</label>
                <BaseToggleSwitch id="stackable" v-model="form.stackable" />
              </div>
              <div class="field field--switch">
                <label for="refundable">{{ $t('discountForm.refundableLabel') }}</label>
                <BaseToggleSwitch id="refundable" v-model="form.refundable" />
              </div>
              <div class="field field--switch">
                <label for="enabled">{{ $t('discountForm.enabledLabel') }}</label>
                <BaseToggleSwitch id="enabled" v-model="form.enabled" />
              </div>
            </div>
          </template>
        </BaseCard>

        <BaseCard v-if="form.kind === 'promotion'" @focusin="activeSection = 'availability'">
          <template #title>{{ $t('discountForm.promotionDetailsTitle') }}</template>
          <template #content>
            <div class="field-grid">
              <div class="field">
                <label for="active_from">{{ $t('discountForm.activeFromLabel') }}</label>
                <BaseInputText id="active_from" v-model="form.promotion.active_from" type="datetime-local" :invalid="!!errors['promotion.active_from']" />
                <small v-if="errors['promotion.active_from']" class="text-danger text-[0.8125rem]">{{ errors['promotion.active_from'] }}</small>
              </div>
              <div class="field">
                <label for="active_until">{{ $t('discountForm.activeUntilLabel') }}</label>
                <BaseInputText id="active_until" v-model="form.promotion.active_until" type="datetime-local" />
              </div>
            </div>
          </template>
        </BaseCard>

        <BaseCard v-else-if="form.kind === 'coupon'" @focusin="activeSection = 'availability'">
          <template #title>{{ $t('discountForm.couponDetailsTitle') }}</template>
          <template #content>
            <p class="period-label">{{ $t('discountForm.issuancePeriodLabel') }}</p>
            <div class="field-grid">
              <div class="field">
                <label for="issued_from">{{ $t('discountForm.issuedFromLabel') }}</label>
                <BaseInputText id="issued_from" v-model="form.coupon.issued_from" type="datetime-local" />
              </div>
              <div class="field">
                <label for="issued_until">{{ $t('discountForm.issuedUntilLabel') }}</label>
                <BaseInputText id="issued_until" v-model="form.coupon.issued_until" type="datetime-local" />
              </div>
            </div>
            <p class="period-label">{{ $t('discountForm.redemptionPeriodLabel') }}</p>
            <div class="field-grid">
              <div class="field">
                <label for="valid_from">{{ $t('discountForm.validFromLabel') }}</label>
                <BaseInputText id="valid_from" v-model="form.coupon.valid_from" type="datetime-local" />
              </div>
              <div class="field">
                <label for="valid_until">{{ $t('discountForm.validUntilLabel') }}</label>
                <BaseInputText id="valid_until" v-model="form.coupon.valid_until" type="datetime-local" />
              </div>
            </div>
            <p v-if="isEdit" class="coupon-codes-hint">
              {{ $t('discountForm.manageCouponCodesHint') }}
              <RouterLink :to="{ name: 'discount-show', params: { id: discountId } }">{{ $t('discountForm.manageCouponCodesLink') }}</RouterLink>
            </p>
          </template>
        </BaseCard>

        <BaseCard v-if="form.kind === 'coupon' && !isEdit" @focusin="activeSection = 'availability'">
          <template #title>{{ $t('discountForm.couponCodesTitle') }}</template>
          <template #content>
            <p class="usage-limits-hint">
              {{ $t('discountForm.couponCodesHint') }}
            </p>
            <BaseMessage v-if="errors.coupon" severity="error" :closable="false">{{ errors.coupon }}</BaseMessage>
            <BaseSelectButton
              v-model="couponCodeMode"
              :options="[
                { label: $t('discountForm.oneoffOption'), value: 'oneoff' },
                { label: $t('discountForm.bulkOption'), value: 'bulk' },
              ]"
              option-label="label"
              option-value="value"
            />

            <div class="field-grid coupon-code-fields">
              <template v-if="couponCodeMode === 'oneoff'">
                <div class="field">
                  <label for="coupon_code">{{ $t('discountForm.codeLabelOptional') }}</label>
                  <BaseInputText id="coupon_code" v-model="form.couponCode.code" :placeholder="$t('discountForm.codePlaceholder')" />
                </div>
                <div class="field">
                  <label for="coupon_code_customer">{{ $t('discountForm.assignCustomerLabel') }}</label>
                  <BaseSelect
                    id="coupon_code_customer"
                    v-model="form.couponCode.customerId"
                    :options="customerOptions"
                    option-label="label"
                    option-value="value"
                    filter
                    show-clear
                    :placeholder="$t('discountForm.anyonePlaceholder')"
                  />
                </div>
                <div class="field">
                  <label for="coupon_code_max_redemptions">{{ $t('discountForm.maxRedemptionsLabel') }}</label>
                  <BaseInputNumber id="coupon_code_max_redemptions" v-model="form.couponCode.maxRedemptions" :min="1" />
                </div>
              </template>

              <template v-else>
                <div class="field field--full">
                  <BaseSelectButton
                    v-model="couponBulkMode"
                    :options="[
                      { label: $t('discountForm.anonymousOption'), value: 'count' },
                      { label: $t('discountForm.personalizedOption'), value: 'customers' },
                    ]"
                    option-label="label"
                    option-value="value"
                  />
                </div>
                <div v-if="couponBulkMode === 'count'" class="field">
                  <label for="coupon_code_count">{{ $t('discountForm.howManyCodesLabel') }}</label>
                  <BaseInputNumber id="coupon_code_count" v-model="form.couponCode.count" :min="1" :max="5000" />
                </div>
                <div v-else class="field field--full">
                  <label for="coupon_code_customers">{{ $t('discountForm.customersOneCodeEachLabel') }}</label>
                  <BaseMultiSelect
                    id="coupon_code_customers"
                    v-model="form.couponCode.customerIds"
                    :options="customerOptions"
                    option-label="label"
                    option-value="value"
                    filter
                  />
                </div>
                <div class="field">
                  <label for="coupon_code_prefix">{{ $t('discountForm.prefixLabel') }}</label>
                  <BaseInputText id="coupon_code_prefix" v-model="form.couponCode.prefix" :placeholder="$t('discountForm.prefixPlaceholder')" />
                </div>
                <div class="field">
                  <label for="coupon_code_suffix">{{ $t('discountForm.suffixLabel') }}</label>
                  <BaseInputText id="coupon_code_suffix" v-model="form.couponCode.suffix" :placeholder="$t('discountForm.suffixPlaceholder')" />
                </div>
                <div class="field">
                  <label for="coupon_code_bulk_max_redemptions">{{ $t('discountForm.maxRedemptionsPerCodeLabel') }}</label>
                  <BaseInputNumber id="coupon_code_bulk_max_redemptions" v-model="form.couponCode.maxRedemptions" :min="1" />
                </div>
              </template>
            </div>
          </template>
        </BaseCard>

        <BaseCard v-if="form.kind === 'loyalty'" @focusin="activeSection = 'availability'">
          <template #title>{{ $t('discountForm.loyaltyDetailsTitle') }}</template>
          <template #content>
            <div class="field-grid">
              <div class="field">
                <label for="loyalty_active_from">{{ $t('discountForm.activeFromLabel') }}</label>
                <BaseInputText id="loyalty_active_from" v-model="form.loyalty.active_from" type="datetime-local" :invalid="!!errors['loyalty.active_from']" />
                <small v-if="errors['loyalty.active_from']" class="text-danger text-[0.8125rem]">{{ errors['loyalty.active_from'] }}</small>
              </div>
              <div class="field">
                <label for="loyalty_active_until">{{ $t('discountForm.activeUntilLabel') }}</label>
                <BaseInputText id="loyalty_active_until" v-model="form.loyalty.active_until" type="datetime-local" />
              </div>
              <div class="field">
                <label for="points_expire_after_days">{{ $t('discountForm.pointsExpireAfterLabel') }}</label>
                <BaseInputNumber id="points_expire_after_days" v-model="form.loyalty.points_expire_after_days" :min="1" :placeholder="$t('discountForm.neverPlaceholder')" />
              </div>
            </div>
            <p class="usage-limits-hint">
              {{ $t('discountForm.loyaltyExpiryHint') }}
            </p>
          </template>
        </BaseCard>

        <BaseCard @focusin="activeSection = 'discount'">
          <template #title>{{ $t('discountForm.effectsTitle') }}</template>
          <template #content>
            <div class="effects-list">
              <template v-for="(effect, i) in form.effects" :key="i">
                <hr v-if="i > 0" class="effect-divider" />
                <EffectEditor
                  :model-value="effect"
                  :kind="form.kind"
                  @update:model-value="(v) => (form.effects[i] = v)"
                  @remove="removeEffect(i)"
                />
              </template>
              <p v-if="!form.effects.length" class="empty-hint">{{ $t('discountForm.noEffectsYet') }}</p>
            </div>
            <BaseButton text :label="$t('discountForm.addEffectButton')" @click="addEffect" />
          </template>
        </BaseCard>

        <BaseCard @focusin="activeSection = 'eligibility'">
          <template #title>{{ $t('discountForm.eligibilityTitle') }}</template>
          <template #content>
            <ConditionTreeEditor v-model="form.eligibility_condition" />
          </template>
        </BaseCard>

        <BaseCard @focusin="activeSection = 'usage'">
          <template #title>{{ $t('discountForm.usageLimitsTitle') }}</template>
          <template #content>
            <p class="usage-limits-hint">{{ $t('discountForm.usageLimitsHint') }}</p>
            <div class="field-grid">
              <div class="field">
                <label for="max_redemptions">{{ $t('discountForm.maxRedemptionsLabel') }}</label>
                <BaseInputNumber id="max_redemptions" v-model="form.max_redemptions" :min="1" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
              <div class="field">
                <label for="max_redemptions_per_customer">{{ $t('discountForm.maxRedemptionsPerCustomerLabel') }}</label>
                <BaseInputNumber id="max_redemptions_per_customer" v-model="form.max_redemptions_per_customer" :min="1" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
              <div class="field">
                <label for="max_redemptions_per_day">{{ $t('discountForm.maxRedemptionsPerDayLabel') }}</label>
                <BaseInputNumber id="max_redemptions_per_day" v-model="form.max_redemptions_per_day" :min="1" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
              <div class="field">
                <label for="max_redemption_amount">{{ $t('discountForm.maxRedemptionAmountLabel') }}</label>
                <BaseInputNumber id="max_redemption_amount" v-model="form.max_redemption_amount" :min="0" :min-fraction-digits="2" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
              <div class="field">
                <label for="max_redemption_amount_per_day">{{ $t('discountForm.maxRedemptionAmountPerDayLabel') }}</label>
                <BaseInputNumber id="max_redemption_amount_per_day" v-model="form.max_redemption_amount_per_day" :min="0" :min-fraction-digits="2" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
              <div class="field">
                <label for="max_redemption_amount_per_customer">{{ $t('discountForm.maxRedemptionAmountPerCustomerLabel') }}</label>
                <BaseInputNumber id="max_redemption_amount_per_customer" v-model="form.max_redemption_amount_per_customer" :min="0" :min-fraction-digits="2" :placeholder="$t('discountForm.unlimitedPlaceholder')" />
              </div>
            </div>
          </template>
        </BaseCard>

        <BaseCard v-if="isEdit">
          <template #title>{{ $t('discountForm.stackingTitle') }}</template>
          <template #content>
            <p class="usage-limits-hint">
              {{ $t('discountForm.stackingHint') }}
            </p>
            <div class="field">
              <label for="compatible_discounts">{{ $t('discountForm.compatibleWithLabel') }}</label>
              <BaseMultiSelect
                id="compatible_discounts"
                :model-value="compatibleDiscountIds"
                :options="discountOptions"
                option-label="label"
                option-value="value"
                filter
                :placeholder="$t('discountForm.noExceptionsPlaceholder')"
                :loading="savingCompatibility"
                @update:model-value="updateCompatibleDiscounts"
              />
            </div>
          </template>
        </BaseCard>

        <BaseCard v-if="form.kind === 'coupon'">
          <template #title>{{ $t('discountForm.designTitle') }}</template>
          <template #content>
            <p class="design-hint">{{ $t('discountForm.designHint') }}</p>

            <div class="field">
              <label for="design_image">{{ $t('discountForm.designImageLabel') }}</label>
              <img
                v-if="designImagePreviewUrl"
                :src="designImagePreviewUrl"
                :alt="$t('discountForm.newDesignImageAlt')"
                class="design-image-preview"
              />
              <img
                v-else-if="existingDesignImageUrl"
                :src="apiFileUrl(existingDesignImageUrl)"
                :alt="$t('discountForm.currentDesignImageAlt')"
                class="design-image-preview"
              />
              <input id="design_image" type="file" accept="image/png,image/jpeg,image/webp,image/gif" @change="onDesignImageSelected" />
            </div>

            <div class="field">
              <label for="design_html">{{ $t('discountForm.designHtmlLabel') }}</label>
              <BaseTextarea id="design_html" v-model="form.coupon.design_html" rows="6" auto-resize />
            </div>

            <div v-if="form.coupon.design_html" class="field">
              <span class="preview-label">{{ $t('discountForm.designPreviewLabel') }}</span>
              <!-- eslint-disable-next-line vue/no-v-html -- the one deliberate v-html in this app; sanitizeHtml() is the only thing ever passed to it -->
              <div class="design-preview" v-html="sanitizeHtml(form.coupon.design_html)" />
            </div>
          </template>
        </BaseCard>

        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>

        <div class="form-actions">
          <BaseButton type="button" text :label="$t('discountForm.cancelButton')" @click="cancel" />
          <BaseButton type="submit" :label="isEdit ? $t('discountForm.saveButton') : $t('discountForm.createButton')" :loading="saving" />
        </div>
      </form>

      <aside v-if="showSummary" class="discount-form-summary">
        <DiscountSummarySidebar :form="form" :timezone="auth.project?.timezone" :active-section="activeSection" />
      </aside>
    </div>

    <UnsavedChangesDialog :visible="showUnsavedDialog" @stay="cancelLeave" @discard="confirmLeave" />
  </AppShell>
</template>

<style scoped>
.discount-form-layout {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1.5rem;
  align-items: start;
}

/* The summary sidebar renders above the editor on narrow/medium screens
   (order: -1, simple DOM-order reflow) rather than a collapsible panel —
   its own content is kept short by design, so it stays reasonably compact
   even stacked above the form. 1024px is a deliberate, narrower-than-usual
   breakpoint of its own (not reused from AppShell's 900px nav-collapse
   point) — this sidebar is a second column on top of the nav sidebar, so it
   needs more headroom before appearing than the nav drawer alone does, to
   avoid cramping the eligibility/effect rows this page deliberately keeps
   compact and single-line. */
.discount-form-summary {
  order: -1;
}

@media (min-width: 1024px) {
  .discount-form-layout--with-summary {
    grid-template-columns: 1fr minmax(240px, 300px);
  }

  .discount-form-summary {
    order: 0;
    position: sticky;
    top: 1rem;
    align-self: start;
  }
}

.discount-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 1rem;
  min-width: 0;
}

.field-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.field label {
  font-size: 0.875rem;
  font-weight: 600;
}

.field--switch {
  flex-direction: row;
  align-items: center;
  gap: 0.75rem;
}

.field--full {
  grid-column: 1 / -1;
}

.coupon-code-fields {
  margin-top: 1rem;
}

.usage-limits-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}

.period-label {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--color-text-muted);
  margin: 0 0 0.5rem;
}

.period-label:not(:first-child) {
  margin-top: 1.25rem;
}

.coupon-codes-hint {
  margin: 1.25rem 0 0;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.coupon-codes-hint a {
  color: var(--color-primary);
  text-decoration: none;
}

.coupon-codes-hint a:hover {
  text-decoration: underline;
}

.design-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}

.design-image-preview {
  width: 10rem;
  height: 10rem;
  object-fit: cover;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  margin-bottom: 0.5rem;
}

.preview-label {
  font-size: 0.875rem;
  font-weight: 600;
}

.design-preview {
  padding: 0.75rem 1rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
}

.effects-list {
  display: flex;
  flex-direction: column;
}

/* Sibling effects are separated by this divider, not by each effect owning
   its own bordered box — EffectEditor.vue's root is plain vertical padding,
   so this is the only line drawn between them (component-design.md: cards
   communicate hierarchy, dividers communicate siblings). */
.effect-divider {
  border: none;
  border-top: 1px solid var(--color-border);
  margin: 0;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0;
  padding: 1rem 0;
}

/* AppShell's own scroll container (.app-shell__content) has bottom padding
   of its own — a plain `bottom: 0` sticks this to the top of THAT padding,
   leaving a gap (the padding's own height) between the footer and the real
   bottom edge, through which whatever's next in the page peeks through. The
   negative margin/bottom bleeds the footer into that padding and back out to
   the true edge; the padding added back here keeps the buttons visually
   inset the same amount as before. */
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  position: sticky;
  bottom: -1.5rem;
  margin: 0 -1.25rem -1.5rem;
  padding: 1rem 1.25rem 1.5rem;
  background: var(--color-bg);
  border-top: 1px solid var(--color-border);
  z-index: 1;
}
</style>
