<script setup>
import { computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import CampaignStatusTags from '@/components/CampaignStatusTags.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getCampaign, updateCampaign } from '@/api/campaigns'
import { listDiscounts } from '@/api/discounts'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatDateTime } from '@/lib/format'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const campaign = ref(null)
const loadError = ref('')
const discounts = ref([])
const discountsLoading = ref(false)
const toggling = ref(false)
const archiving = ref(false)

async function loadCampaign() {
  loadError.value = ''
  try {
    campaign.value = await getCampaign(route.params.id, { token: auth.token, projectId: auth.project?.id })
    await loadDiscounts()
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('campaignDetail.loadError')
  }
}

async function loadDiscounts() {
  discountsLoading.value = true
  try {
    discounts.value = await listDiscounts({ campaignId: campaign.value.id, token: auth.token, projectId: auth.project?.id })
  } finally {
    discountsLoading.value = false
  }
}

async function toggleEnabled() {
  toggling.value = true
  try {
    campaign.value = await updateCampaign(campaign.value.id, { enabled: !campaign.value.enabled }, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: campaign.value.enabled ? t('campaignDetail.enabledToast') : t('campaignDetail.pausedToast'), life: 3000 })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('campaignDetail.updateError'), detail: e.message, life: 4000 })
  } finally {
    toggling.value = false
  }
}

async function toggleArchived() {
  archiving.value = true
  try {
    campaign.value = await updateCampaign(campaign.value.id, { archived: !campaign.value.archived }, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: campaign.value.archived ? t('campaignDetail.archivedToast') : t('campaignDetail.unarchivedToast'), life: 3000 })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('campaignDetail.updateError'), detail: e.message, life: 4000 })
  } finally {
    archiving.value = false
  }
}

function editCampaign() {
  router.push({ name: 'campaign-edit', params: { id: campaign.value.id } })
}

function viewDiscount(discount) {
  router.push({ name: 'discount-show', params: { id: discount.id } })
}

function editDiscount(discount) {
  router.push({ name: 'discount-edit', params: { id: discount.id } })
}

function newDiscount() {
  router.push({ name: 'discount-new', query: { campaign_id: campaign.value.id } })
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

onMounted(loadCampaign)
</script>

<template>
  <AppShell>
    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <template v-if="campaign">
      <PageHeader>
        <template #title>
          <h2>{{ campaign.name }}</h2>
          <CampaignStatusTags :campaign="campaign" />
        </template>
        <template #actions>
          <BaseButton
            text
            :label="campaign.archived ? $t('campaignDetail.unarchiveButton') : $t('campaignDetail.archiveButton')"
            :loading="archiving"
            @click="toggleArchived"
          />
          <BaseButton text :label="campaign.enabled ? $t('campaignDetail.pauseButton') : $t('campaignDetail.enableButton')" :loading="toggling" @click="toggleEnabled" />
          <BaseButton :label="$t('campaignDetail.editButton')" @click="editCampaign" />
        </template>
      </PageHeader>

      <BaseCard class="section-card">
        <template #title>{{ $t('campaignDetail.detailsTitle') }}</template>
        <template #content>
          <dl class="details">
            <dt>{{ $t('campaignDetail.validFromLabel') }}</dt>
            <dd>{{ campaign.valid_from ? formatDateTime(campaign.valid_from, auth.project?.timezone) : $t('campaignDetail.noStartDate') }}</dd>
            <dt>{{ $t('campaignDetail.validUntilLabel') }}</dt>
            <dd>{{ campaign.valid_until ? formatDateTime(campaign.valid_until, auth.project?.timezone) : $t('campaignDetail.noEndDate') }}</dd>
            <dt>{{ $t('campaignDetail.createdLabel') }}</dt>
            <dd>{{ formatDateTime(campaign.created_at, auth.project?.timezone) }}</dd>
          </dl>
        </template>
      </BaseCard>

      <BaseCard class="section-card">
        <template #title>{{ $t('campaignDetail.discountsTitle') }}</template>
        <template #content>
          <BaseTable
            :data="discounts"
            :columns="discountColumns"
            :loading="discountsLoading"
            row-key="id"
            :create-label="$t('campaignDetail.newDiscountButton')"
            @row-click="viewDiscount($event.data)"
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
    </template>
  </AppShell>
</template>
