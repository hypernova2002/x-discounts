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
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getCampaign, createCampaign, updateCampaign } from '@/api/campaigns'
import { campaignInputSchema } from '@/models/campaign'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

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

function isoToLocalInput(iso) {
  return iso ? iso.slice(0, 16) : ''
}
function localInputToIso(local) {
  if (!local) return null
  return local.length === 16 ? `${local}:00.000Z` : local
}

async function load() {
  loading.value = true
  try {
    const data = await getCampaign(campaignId.value, { token: auth.token, projectId: auth.project?.id })
    form.name = data.name
    form.enabled = data.enabled
    form.valid_from = isoToLocalInput(data.valid_from)
    form.valid_until = isoToLocalInput(data.valid_until)
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('campaignForm.loadError')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (isEdit.value) load()
})

async function submit() {
  errors.value = {}

  const payload = {
    name: form.name,
    enabled: form.enabled,
    valid_from: localInputToIso(form.valid_from),
    valid_until: localInputToIso(form.valid_until),
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
      toast.add({ severity: 'success', summary: t('campaignForm.updatedToast'), life: 3000 })
      router.push({ name: 'campaign-show', params: { id: campaignId.value } })
    } else {
      const campaign = await createCampaign(result.data, { token: auth.token, projectId: auth.project?.id })
      toast.add({ severity: 'success', summary: t('campaignForm.createdToast'), life: 3000 })
      router.push({ name: 'campaign-show', params: { id: campaign.id } })
    }
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('campaignForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
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
  </AppShell>
</template>

<style scoped>
.campaign-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 1rem;
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
