<script setup>
import { computed, reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { getMembershipScheme, createMembershipScheme, updateMembershipScheme } from '@/api/membershipSchemes'
import { membershipSchemeInputSchema } from '@/models/membershipScheme'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const schemeId = computed(() => route.params.id || null)
const isEdit = computed(() => !!schemeId.value)

const loading = ref(false)
const saving = ref(false)
const loadError = ref('')
const errors = ref({})

const form = reactive({ name: '' })

async function load() {
  loading.value = true
  try {
    const data = await getMembershipScheme(schemeId.value, { token: auth.token, projectId: auth.project?.id })
    form.name = data.name
  } catch (e) {
    loadError.value = e instanceof ApiError ? e.message : t('membershipSchemeForm.loadError')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (isEdit.value) load()
})

async function submit() {
  errors.value = {}

  const payload = { name: form.name }

  const result = membershipSchemeInputSchema(t).safeParse(payload)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  saving.value = true
  try {
    if (isEdit.value) {
      await updateMembershipScheme(schemeId.value, result.data, { token: auth.token, projectId: auth.project?.id })
      toast.add({ severity: 'success', summary: t('membershipSchemeForm.schemeUpdated'), life: 3000 })
      router.push({ name: 'membership-scheme-show', params: { id: schemeId.value } })
    } else {
      const scheme = await createMembershipScheme(result.data, { token: auth.token, projectId: auth.project?.id })
      toast.add({ severity: 'success', summary: t('membershipSchemeForm.schemeCreated'), life: 3000 })
      router.push({ name: 'membership-scheme-show', params: { id: scheme.id } })
    }
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('membershipSchemeForm.genericError') }
  } finally {
    saving.value = false
  }
}

function cancel() {
  router.push({ name: 'membership-schemes' })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <h2>{{ isEdit ? $t('membershipSchemeForm.editTitle') : $t('membershipSchemeForm.newTitle') }}</h2>
      </template>
    </PageHeader>

    <BaseMessage v-if="loadError" severity="error" :closable="false">{{ loadError }}</BaseMessage>

    <form class="scheme-form" @submit.prevent="submit">
      <BaseCard>
        <template #content>
          <div class="field">
            <label for="name">{{ $t('membershipSchemeForm.nameLabel') }}</label>
            <BaseInputText id="name" v-model="form.name" :invalid="!!errors.name" />
            <small v-if="errors.name" class="text-danger text-[0.8125rem]">{{ errors.name }}</small>
          </div>
        </template>
      </BaseCard>

      <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>

      <div class="form-actions">
        <BaseButton type="button" text :label="$t('membershipSchemeForm.cancelButton')" @click="cancel" />
        <BaseButton type="submit" :label="isEdit ? $t('membershipSchemeForm.saveChangesButton') : $t('membershipSchemeForm.createButton')" :loading="saving" />
      </div>
    </form>
  </AppShell>
</template>

<style scoped>
.scheme-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 1rem;
  max-width: 24rem;
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

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}
</style>
