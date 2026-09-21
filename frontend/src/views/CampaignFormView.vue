<script>
// Module-level (not per-instance) so it survives navigating away to edit a
// discount and back — a plain `<script>` block's top-level bindings are
// shared across every instance of this component, unlike `<script setup>`'s,
// which are re-created on each mount. Holds at most one in-progress edit —
// only ever written just before navigating to a discount's own form, and
// read/cleared the moment this view mounts again, so it can't leak into an
// unrelated later visit to this screen.
let campaignDraft = null

function saveCampaignDraft(campaignId, form) {
  campaignDraft = { campaignId, form: { ...form } }
}

function takeCampaignDraft(campaignId) {
  const draft = campaignDraft && campaignDraft.campaignId === campaignId ? campaignDraft.form : null
  campaignDraft = null
  return draft
}

function clearCampaignDraft() {
  campaignDraft = null
}
</script>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseToggleSwitch from '@/components/base/BaseToggleSwitch.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import UnsavedChangesDialog from '@/components/UnsavedChangesDialog.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getCampaign, createCampaign, updateCampaign } from '@/api/campaigns'
import { listDiscounts } from '@/api/discounts'
import { campaignInputSchema } from '@/models/campaign'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'
import { useUnsavedChangesGuard } from '@/composables/useUnsavedChangesGuard'
import { isoToZonedInput, zonedInputToIso } from '@/lib/timezone'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const campaignId = computed(() => route.params.id || null)
const isEdit = computed(() => !!campaignId.value)

const loading = ref(false)
const saving = ref(false)
const loadError = ref('')
const errors = ref({})

const form = reactive({
  name: '',
  enabled: true,
  valid_from: '',
  valid_until: '',
})

// Snapshotted right after the form reflects "what's actually saved" (on mount
// for a new campaign, after load() for an existing one) — isDirty compares
// against this, not against empty defaults, so editing an existing campaign
// back to its original values doesn't still read as dirty.
const initialSnapshot = ref(JSON.stringify(form))

function isDirty() {
  return JSON.stringify(form) !== initialSnapshot.value
}

const { showDialog: showUnsavedDialog, confirmLeave, cancelLeave, bypassOnce } = useUnsavedChangesGuard(isDirty)

async function load() {
  loading.value = true
  try {
    const data = await getCampaign(campaignId.value, { token: auth.token, projectId: auth.project?.id })
    form.name = data.name
    form.enabled = data.enabled
    form.valid_from = isoToZonedInput(data.valid_from, auth.project?.timezone)
    form.valid_until = isoToZonedInput(data.valid_until, auth.project?.timezone)
    // The dirty baseline is always "what the server has," whether or not a
    // draft ends up applied on top of it — a draft carrying real unsaved
    // edits should still read as dirty, not as freshly clean.
    initialSnapshot.value = JSON.stringify(form)

    // A pending draft (left just before navigating off to edit one of this
    // campaign's discounts) wins over what the server has, so unsaved edits
    // survive that round trip instead of being clobbered by the fresh fetch.
    const draft = takeCampaignDraft(campaignId.value)
    if (draft) Object.assign(form, draft)

    await loadDiscounts()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('campaignForm.loadError')
  } finally {
    loading.value = false
  }
}

// --- discounts (edit mode only — a campaign needs to exist before it can have any) ---

const discounts = ref([])
const discountsLoading = ref(false)

async function loadDiscounts() {
  discountsLoading.value = true
  try {
    discounts.value = await listDiscounts({ campaignId: campaignId.value, token: auth.token, projectId: auth.project?.id })
  } finally {
    discountsLoading.value = false
  }
}

function editDiscount(discount) {
  saveCampaignDraft(campaignId.value, form)
  bypassOnce()
  router.push({ name: 'discount-edit', params: { id: discount.id }, query: { return_to: 'campaign-edit' } })
}

function newDiscount() {
  saveCampaignDraft(campaignId.value, form)
  bypassOnce()
  router.push({ name: 'discount-new', query: { campaign_id: campaignId.value, return_to: 'campaign-edit' } })
}

const discountColumns = computed(() => [
  { field: 'name', header: t('campaignDetail.nameColumn'), sortable: true, hideable: false, filter: { type: 'string' } },
  {
    field: 'kind',
    header: t('campaignDetail.kindColumn'),
    filter: {
      type: 'enum',
      options: [
        { label: t('discountForm.kindPromotion'), value: 'promotion' },
        { label: t('discountForm.kindCoupon'), value: 'coupon' },
        { label: t('discountForm.kindLoyalty'), value: 'loyalty' },
      ],
    },
  },
  { field: 'key', header: t('campaignDetail.keyColumn'), sortable: true, filter: { type: 'string' } },
  {
    field: 'enabled',
    header: t('campaignDetail.statusColumn'),
    filter: {
      type: 'enum',
      options: [
        { label: t('campaignDetail.statusEnabled'), value: true },
        { label: t('campaignDetail.statusDisabled'), value: false },
      ],
    },
  },
  { field: 'actions', header: t('campaignDetail.actionsColumn'), hideable: false },
])

onMounted(() => {
  if (isEdit.value) load()
})

async function submit() {
  errors.value = {}

  const payload = {
    name: form.name,
    enabled: form.enabled,
    valid_from: zonedInputToIso(form.valid_from, auth.project?.timezone),
    valid_until: zonedInputToIso(form.valid_until, auth.project?.timezone),
  }

  const result = campaignInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  saving.value = true
  try {
    if (isEdit.value) {
      await updateCampaign(campaignId.value, result.data, { token: auth.token, projectId: auth.project?.id })
      clearCampaignDraft()
      toast.add({ severity: 'success', summary: t('campaignForm.updatedToast'), life: 3000 })
      bypassOnce()
      router.push({ name: 'campaign-show', params: { id: campaignId.value } })
    } else {
      const campaign = await createCampaign(result.data, { token: auth.token, projectId: auth.project?.id })
      toast.add({ severity: 'success', summary: t('campaignForm.createdToast'), life: 3000 })
      bypassOnce()
      router.push({ name: 'campaign-show', params: { id: campaign.id } })
    }
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('campaignForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
  clearCampaignDraft()
  router.push({ name: 'campaigns' })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <h2>{{ isEdit ? $t('campaignForm.editTitle') : $t('campaignForm.newTitle') }}</h2>
      </template>
    </PageHeader>

    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <form class="campaign-form" @submit.prevent="submit">
      <BaseCard>
        <template #content>
          <div class="field-grid">
            <div class="field">
              <label for="name">{{ $t('campaignForm.nameLabel') }}</label>
              <BaseInputText id="name" v-model="form.name" :invalid="!!errors.name" />
              <small v-if="errors.name" class="text-danger text-[0.8125rem]">{{ errors.name }}</small>
            </div>
            <div class="field field--switch">
              <label for="enabled">{{ $t('campaignForm.enabledLabel') }}</label>
              <BaseToggleSwitch id="enabled" v-model="form.enabled" />
            </div>
            <div class="field">
              <label for="valid_from">{{ $t('campaignForm.validFromLabel') }}</label>
              <BaseInputText id="valid_from" v-model="form.valid_from" type="datetime-local" />
            </div>
            <div class="field">
              <label for="valid_until">{{ $t('campaignForm.validUntilLabel') }}</label>
              <BaseInputText id="valid_until" v-model="form.valid_until" type="datetime-local" />
            </div>
          </div>
          <p class="text-sm text-text-muted mt-4">
            {{ $t('campaignForm.hint') }}
          </p>
        </template>
      </BaseCard>

      <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>

      <div class="form-actions">
        <BaseButton type="button" text :label="$t('campaignForm.cancelButton')" @click="cancel" />
        <BaseButton type="submit" :label="isEdit ? $t('campaignForm.saveButton') : $t('campaignForm.createButton')" :loading="saving" />
      </div>
    </form>

    <BaseCard v-if="isEdit" class="section-card discounts-card">
      <template #title>{{ $t('campaignDetail.discountsTitle') }}</template>
      <template #content>
        <BaseTable
          :data="discounts"
          :columns="discountColumns"
          :loading="discountsLoading"
          row-key="id"
          :create-label="$t('campaignDetail.newDiscountButton')"
          @row-click="editDiscount($event.data)"
          @refresh="loadDiscounts"
          @create="newDiscount"
        >
          <template #cell-kind="{ data }"><BaseTag :value="data.kind" /></template>
          <template #cell-enabled="{ data }">
            <BaseTag v-if="!data.enabled" severity="secondary" :value="$t('campaignDetail.statusDisabled')" />
          </template>
          <template #cell-actions="{ data }">
            <BaseButton text icon="pi pi-pencil" :aria-label="$t('campaignDetail.editButton')" @click.stop="editDiscount(data)" />
          </template>
          <template #empty>{{ $t('campaignDetail.noDiscountsHint') }}</template>
        </BaseTable>
      </template>
    </BaseCard>

    <UnsavedChangesDialog :visible="showUnsavedDialog" @stay="cancelLeave" @discard="confirmLeave" />
  </AppShell>
</template>

<style scoped>
.campaign-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 1rem;
}

.discounts-card {
  margin-top: 1.5rem;
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

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}
</style>
