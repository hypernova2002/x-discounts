<script setup>
import { computed, ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseInputNumber from '@/components/base/BaseInputNumber.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import MembershipRequirementEditor from '@/components/discounts/MembershipRequirementEditor.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getMembershipScheme, createMembershipTier, updateMembershipTier, evaluateMembershipSchemes } from '@/api/membershipSchemes'
import { membershipTierInputSchema } from '@/models/membershipTier'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

const route = useRoute()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const scheme = ref(null)
const loadError = ref('')
const evaluating = ref(false)

async function runEvaluation() {
  evaluating.value = true
  try {
    const data = await evaluateMembershipSchemes({ token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('membershipSchemeDetail.reevaluatedCustomers', { count: data.evaluated }), life: 3000 })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('membershipSchemeDetail.evaluationFailed'), detail: e.message, life: 4000 })
  } finally {
    evaluating.value = false
  }
}

async function loadScheme() {
  loadError.value = ''
  try {
    scheme.value = await getMembershipScheme(route.params.id, { token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('membershipSchemeDetail.loadError')
  }
}

onMounted(loadScheme)

const tierColumns = computed(() => [
  { field: 'rank', header: t('membershipSchemeDetail.columns.rank'), sortable: true, hideable: false, filter: { type: 'number' } },
  { field: 'name', header: t('membershipSchemeDetail.columns.name'), sortable: true, hideable: false, filter: { type: 'string' } },
  {
    field: 'auto_assignable',
    header: t('membershipSchemeDetail.columns.autoJoin'),
    filter: {
      type: 'enum',
      options: [
        { label: t('membershipSchemeDetail.autoJoinAutomatic'), value: true },
        { label: t('membershipSchemeDetail.autoJoinManual'), value: false },
      ],
    },
  },
  { field: 'actions', header: t('membershipSchemeDetail.columns.actions'), hideable: false },
])

// --- add tier ---

const newTierName = ref('')
const newTierRank = ref(null)
const addingTier = ref(false)
const addTierErrors = ref({})

async function addTier() {
  addTierErrors.value = {}

  const payload = { name: newTierName.value, rank: newTierRank.value }
  const result = membershipTierInputSchema(t).safeParse(payload)
  if (!result.success) {
    addTierErrors.value = toFieldErrors(result.error)
    return
  }

  addingTier.value = true
  try {
    await createMembershipTier(scheme.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    newTierName.value = ''
    newTierRank.value = null
    toast.add({ severity: 'success', summary: t('membershipSchemeDetail.tierAdded'), life: 3000 })
    await loadScheme()
  } catch (e) {
    addTierErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('membershipSchemeDetail.genericError') }
  } finally {
    addingTier.value = false
  }
}

// --- edit tier ---

const editingTier = ref(null)
const editForm = ref({ name: '', rank: null, requirements_condition: null, grace_period_days: null })
const editSaving = ref(false)
const editErrors = ref({})

function openEdit(tier) {
  editingTier.value = tier
  editForm.value = {
    name: tier.name,
    rank: tier.rank,
    requirements_condition: Object.keys(tier.requirements_condition || {}).length ? tier.requirements_condition : null,
    grace_period_days: tier.grace_period_days,
  }
  editErrors.value = {}
}

async function saveEdit() {
  editErrors.value = {}

  const result = membershipTierInputSchema(t).safeParse({ name: editForm.value.name, rank: editForm.value.rank })
  if (!result.success) {
    editErrors.value = toFieldErrors(result.error)
    return
  }

  editSaving.value = true
  try {
    await updateMembershipTier(
      scheme.value.id,
      editingTier.value.id,
      {
        name: result.data.name,
        rank: result.data.rank,
        requirements_condition: editForm.value.requirements_condition,
        grace_period_days: editForm.value.grace_period_days,
      },
      { token: auth.token, projectId: auth.project?.id }
    )
    toast.add({ severity: 'success', summary: t('membershipSchemeDetail.tierUpdated'), life: 3000 })
    editingTier.value = null
    await loadScheme()
  } catch (e) {
    editErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('membershipSchemeDetail.genericError') }
  } finally {
    editSaving.value = false
  }
}
</script>

<template>
  <AppShell>
    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <template v-if="scheme">
      <PageHeader>
        <template #title>
          <h2>{{ scheme.name }}</h2>
        </template>
        <template #actions>
          <BaseButton text :label="$t('membershipSchemeDetail.reevaluateButton')" :loading="evaluating" @click="runEvaluation" />
        </template>
      </PageHeader>

      <BaseCard class="section-card">
        <template #title>{{ $t('membershipSchemeDetail.tiersTitle') }}</template>
        <template #content>
          <BaseTable :data="scheme.tiers" :columns="tierColumns" row-key="id" @refresh="loadScheme">
            <template #cell-auto_assignable="{ data }">
              <BaseTag
                :severity="data.auto_assignable ? 'success' : 'secondary'"
                :value="data.auto_assignable ? $t('membershipSchemeDetail.autoJoinAutomatic') : $t('membershipSchemeDetail.autoJoinManual')"
              />
            </template>
            <template #cell-actions="{ data }">
              <BaseButton text icon="pi pi-pencil" :aria-label="$t('membershipSchemeDetail.editButton')" @click="openEdit(data)" />
            </template>
            <template #empty>{{ $t('membershipSchemeDetail.noTiersHint') }}</template>
          </BaseTable>

          <div class="add-tier-form">
            <div class="add-tier-field">
              <BaseInputText v-model="newTierName" :placeholder="$t('membershipSchemeDetail.tierNamePlaceholder')" :invalid="!!addTierErrors.name" />
              <small v-if="addTierErrors.name" class="text-danger text-[0.8125rem]">{{ addTierErrors.name }}</small>
            </div>
            <div class="add-tier-field">
              <BaseInputNumber v-model="newTierRank" :placeholder="$t('membershipSchemeDetail.rankPlaceholder')" :min="0" :invalid="!!addTierErrors.rank" />
              <small v-if="addTierErrors.rank" class="text-danger text-[0.8125rem]">{{ addTierErrors.rank }}</small>
            </div>
            <BaseButton :label="$t('membershipSchemeDetail.addTierButton')" :loading="addingTier" @click="addTier" />
          </div>
          <BaseMessage v-if="addTierErrors._root" severity="error" :closable="false">{{ addTierErrors._root }}</BaseMessage>
        </template>
      </BaseCard>
    </template>

    <BaseDialog :visible="!!editingTier" modal :header="$t('membershipSchemeDetail.editTierDialog.title')" :style="{ width: '40rem' }" @update:visible="editingTier = null">
      <div v-if="editingTier" class="edit-tier-form">
        <label>{{ $t('membershipSchemeDetail.editTierDialog.nameLabel') }}</label>
        <BaseInputText v-model="editForm.name" autofocus :invalid="!!editErrors.name" />
        <small v-if="editErrors.name" class="text-danger text-[0.8125rem]">{{ editErrors.name }}</small>
        <label>{{ $t('membershipSchemeDetail.editTierDialog.rankLabel') }}</label>
        <BaseInputNumber v-model="editForm.rank" :min="0" :invalid="!!editErrors.rank" />
        <small v-if="editErrors.rank" class="text-danger text-[0.8125rem]">{{ editErrors.rank }}</small>
        <label>{{ $t('membershipSchemeDetail.editTierDialog.autoJoinRequirementsLabel') }}</label>
        <p class="requirements-hint">
          {{ $t('membershipSchemeDetail.editTierDialog.autoJoinRequirementsHint') }}
        </p>
        <MembershipRequirementEditor v-model="editForm.requirements_condition" />

        <label for="grace_period_days">{{ $t('membershipSchemeDetail.editTierDialog.gracePeriodLabel') }}</label>
        <BaseInputNumber id="grace_period_days" v-model="editForm.grace_period_days" :placeholder="$t('membershipSchemeDetail.editTierDialog.gracePeriodPlaceholder')" :min="1" />
        <p class="requirements-hint">
          {{ $t('membershipSchemeDetail.editTierDialog.gracePeriodHint') }}
        </p>
        <BaseMessage v-if="editErrors._root" severity="error" :closable="false">{{ editErrors._root }}</BaseMessage>
        <BaseButton :label="$t('membershipSchemeDetail.editTierDialog.saveButton')" :loading="editSaving" @click="saveEdit" />
      </div>
    </BaseDialog>
  </AppShell>
</template>

<style scoped>
.empty-hint {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  margin: 0 0 1rem;
}

.add-tier-form {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  margin-top: 1rem;
}

.add-tier-field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.edit-tier-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.requirements-hint {
  color: var(--color-text-muted);
  font-size: 0.8125rem;
  margin: 0;
}
</style>
