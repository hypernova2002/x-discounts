<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BasePassword from '@/components/base/BasePassword.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import OtpEnrollment from '@/components/OtpEnrollment.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { updateUser } from '@/api/users'
import { updatePassword } from '@/api/me'
import { userInputSchema, changePasswordInputSchema } from '@/models/user'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const profileForm = ref({ name: auth.user?.name ?? '', email: auth.user?.email ?? '' })
const profileErrors = ref({})
const savingProfile = ref(false)

async function saveProfile() {
  profileErrors.value = {}

  const result = userInputSchema(t).safeParse(profileForm.value)
  if (!result.success) {
    profileErrors.value = toFieldErrors(result.error)
    return
  }

  savingProfile.value = true
  try {
    await updateUser(auth.user.id, result.data, { token: auth.token, projectId: auth.project?.id })
    await auth.loadMe(auth.project.id)
    toast.add({ severity: 'success', summary: t('userSettings.profileUpdatedSuccess'), life: 3000 })
  } catch (e) {
    profileErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('userSettings.genericError') }
  } finally {
    savingProfile.value = false
  }
}

const passwordForm = ref({ current_password: '', new_password: '', new_password_confirmation: '' })
const passwordErrors = ref({})
const savingPassword = ref(false)

async function savePassword() {
  passwordErrors.value = {}

  const result = changePasswordInputSchema(t).safeParse(passwordForm.value)
  if (!result.success) {
    passwordErrors.value = toFieldErrors(result.error)
    return
  }

  savingPassword.value = true
  try {
    await updatePassword(result.data, { token: auth.token, projectId: auth.project?.id })
    passwordForm.value = { current_password: '', new_password: '', new_password_confirmation: '' }
    toast.add({ severity: 'success', summary: t('userSettings.passwordUpdatedSuccess'), life: 3000 })
  } catch (e) {
    passwordErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('userSettings.genericError') }
  } finally {
    savingPassword.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <BaseCard class="section-card">
      <template #title>{{ $t('userSettings.profileTitle') }}</template>
      <template #content>
        <form class="settings-form" @submit.prevent="saveProfile">
          <div class="field">
            <label for="settings-name">{{ $t('users.nameLabel') }}</label>
            <BaseInputText id="settings-name" v-model="profileForm.name" :invalid="!!profileErrors.name" />
            <small v-if="profileErrors.name" class="field-error">{{ profileErrors.name }}</small>
          </div>
          <div class="field">
            <label for="settings-email">{{ $t('users.emailLabel') }}</label>
            <BaseInputText id="settings-email" v-model="profileForm.email" type="email" :invalid="!!profileErrors.email" />
            <small v-if="profileErrors.email" class="field-error">{{ profileErrors.email }}</small>
          </div>
          <BaseMessage v-if="profileErrors._root" severity="error" :closable="false">{{ profileErrors._root }}</BaseMessage>
          <div class="form-actions">
            <BaseButton type="submit" :label="$t('userSettings.saveButton')" :loading="savingProfile" />
          </div>
        </form>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ $t('userSettings.passwordTitle') }}</template>
      <template #content>
        <form class="settings-form" @submit.prevent="savePassword">
          <div class="field">
            <label for="current-password">{{ $t('userSettings.currentPasswordLabel') }}</label>
            <BasePassword id="current-password" v-model="passwordForm.current_password" :feedback="false" toggle-mask :invalid="!!passwordErrors.current_password" />
            <small v-if="passwordErrors.current_password" class="field-error">{{ passwordErrors.current_password }}</small>
          </div>
          <div class="field">
            <label for="new-password">{{ $t('userSettings.newPasswordLabel') }}</label>
            <BasePassword id="new-password" v-model="passwordForm.new_password" :feedback="false" toggle-mask :invalid="!!passwordErrors.new_password" />
            <small v-if="passwordErrors.new_password" class="field-error">{{ passwordErrors.new_password }}</small>
          </div>
          <div class="field">
            <label for="new-password-confirmation">{{ $t('userSettings.confirmPasswordLabel') }}</label>
            <BasePassword id="new-password-confirmation" v-model="passwordForm.new_password_confirmation" :feedback="false" toggle-mask :invalid="!!passwordErrors.new_password_confirmation" />
            <small v-if="passwordErrors.new_password_confirmation" class="field-error">{{ passwordErrors.new_password_confirmation }}</small>
          </div>
          <BaseMessage v-if="passwordErrors._root" severity="error" :closable="false">{{ passwordErrors._root }}</BaseMessage>
          <div class="form-actions">
            <BaseButton type="submit" :label="$t('userSettings.saveButton')" :loading="savingPassword" />
          </div>
        </form>
      </template>
    </BaseCard>

    <BaseCard class="section-card">
      <template #title>{{ $t('userSettings.otpTitle') }}</template>
      <template #content>
        <OtpEnrollment />
      </template>
    </BaseCard>
  </AppShell>
</template>

<style scoped>
.settings-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
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

.field-error {
  color: var(--color-danger);
  font-size: 0.8125rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
}
</style>
