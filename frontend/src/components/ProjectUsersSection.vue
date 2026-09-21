<script setup>
import { computed, ref, watch } from 'vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseDialog from '@/components/base/BaseDialog.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BasePassword from '@/components/base/BasePassword.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import { useI18n } from 'vue-i18n'
import { AVAILABLE_LOCALES } from '@/i18n'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listUsers, createUser as createUserRequest, resetUserPassword, resetUserOtp } from '@/api/users'
import { userInputSchema, adminResetPasswordInputSchema } from '@/models/user'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast.js'

// A mountable section, not a route-level page — used inside
// ProjectSettingsView.vue's own BaseCard, which already supplies the
// AppShell/PageHeader/title this component used to own back when it was
// UsersView.vue's own standalone route.
const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

const { data: users, loading, error, reload } = useAsync(() => listUsers({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('users.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'id', header: t('users.idColumn'), sortable: true, hideable: false },
  { field: 'name', header: t('users.nameColumn'), sortable: true, filter: { type: 'string' } },
  { field: 'email', header: t('users.emailColumn'), sortable: true, filter: { type: 'string' } },
  {
    field: 'locale',
    header: t('users.localeColumn'),
    sortable: true,
    filter: { type: 'enum', options: AVAILABLE_LOCALES.map((l) => ({ label: l.label, value: l.code })) },
  },
  {
    field: 'otp_enabled',
    header: t('users.otpColumn'),
    sortable: true,
    filter: {
      type: 'enum',
      options: [
        { label: t('users.otpEnabled'), value: true },
        { label: t('users.otpDisabled'), value: false },
      ],
    },
  },
  { field: 'actions', header: t('users.actionsColumn'), hideable: false },
])

const showCreate = ref(false)
const form = ref({ name: '', email: '' })
const errors = ref({})
const creating = ref(false)

function openCreate() {
  form.value = { name: '', email: '' }
  errors.value = {}
  showCreate.value = true
}

async function createUser() {
  errors.value = {}

  const result = userInputSchema(t).safeParse(form.value)
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  creating.value = true
  try {
    await createUserRequest(result.data, { token: auth.token, projectId: auth.project?.id })
    showCreate.value = false
    form.value = { name: '', email: '' }
    toast.add({ severity: 'success', summary: t('users.createdSuccess'), life: 3000 })
    await reload()
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('users.genericError') }
  } finally {
    creating.value = false
  }
}

const showResetPassword = ref(false)
const resetTargetUser = ref(null)
const resetPasswordForm = ref({ password: '', password_confirmation: '' })
const resetPasswordErrors = ref({})
const resettingPassword = ref(false)

function openResetPassword(user) {
  resetTargetUser.value = user
  resetPasswordForm.value = { password: '', password_confirmation: '' }
  resetPasswordErrors.value = {}
  showResetPassword.value = true
}

async function submitResetPassword() {
  resetPasswordErrors.value = {}

  const result = adminResetPasswordInputSchema(t).safeParse(resetPasswordForm.value)
  if (!result.success) {
    resetPasswordErrors.value = toFieldErrors(result.error)
    return
  }

  resettingPassword.value = true
  try {
    await resetUserPassword(resetTargetUser.value.id, result.data, { token: auth.token, projectId: auth.project?.id })
    showResetPassword.value = false
    toast.add({ severity: 'success', summary: t('users.resetPasswordSuccess'), life: 3000 })
  } catch (e) {
    resetPasswordErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('users.genericError') }
  } finally {
    resettingPassword.value = false
  }
}

const resettingOtpId = ref(null)

async function handleResetOtp(user) {
  resettingOtpId.value = user.id
  try {
    await resetUserOtp(user.id, { token: auth.token, projectId: auth.project?.id })
    toast.add({ severity: 'success', summary: t('users.resetOtpSuccess'), life: 3000 })
    await reload()
  } catch (e) {
    toast.add({ severity: 'error', summary: t('users.genericError'), detail: e.message, life: 4000 })
  } finally {
    resettingOtpId.value = null
  }
}
</script>

<template>
  <div>
    <BaseTable
      :data="users || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('users.searchPlaceholder')"
      :create-label="$t('users.newUserButton')"
      @refresh="reload"
      @create="openCreate"
    >
      <template #cell-locale="{ data }">{{ AVAILABLE_LOCALES.find((l) => l.code === data.locale)?.label ?? data.locale }}</template>
      <template #cell-otp_enabled="{ data }">
        <BaseTag
          :value="data.otp_enabled ? $t('users.otpEnabled') : $t('users.otpDisabled')"
          :severity="data.otp_enabled ? 'success' : 'secondary'"
        />
      </template>
      <template #cell-actions="{ data }">
        <BaseButton text icon="pi pi-key" :aria-label="$t('users.resetPasswordButton')" v-tooltip.bottom="$t('users.resetPasswordButton')" @click.stop="openResetPassword(data)" />
        <BaseButton
          text
          icon="pi pi-shield"
          :aria-label="$t('users.resetOtpButton')"
          v-tooltip.bottom="$t('users.resetOtpButton')"
          :loading="resettingOtpId === data.id"
          @click.stop="handleResetOtp(data)"
        />
      </template>
    </BaseTable>

    <BaseDialog v-model:visible="showCreate" :header="$t('users.newUserDialogHeader')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="createUser">
        <label for="user-name">{{ $t('users.nameLabel') }}</label>
        <BaseInputText id="user-name" v-model="form.name" autofocus :invalid="!!errors.name" />
        <small v-if="errors.name" class="field-error">{{ errors.name }}</small>
        <label for="user-email">{{ $t('users.emailLabel') }}</label>
        <BaseInputText id="user-email" v-model="form.email" type="email" :invalid="!!errors.email" />
        <small v-if="errors.email" class="field-error">{{ errors.email }}</small>
        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('users.createButton')" :loading="creating" />
      </form>
    </BaseDialog>

    <BaseDialog v-model:visible="showResetPassword" :header="$t('users.resetPasswordDialogHeader')" modal :style="{ width: '24rem' }">
      <form class="create-form" @submit.prevent="submitResetPassword">
        <label for="reset-password">{{ $t('users.newPasswordLabel') }}</label>
        <BasePassword id="reset-password" v-model="resetPasswordForm.password" :feedback="false" toggle-mask autofocus :invalid="!!resetPasswordErrors.password" />
        <small v-if="resetPasswordErrors.password" class="field-error">{{ resetPasswordErrors.password }}</small>
        <label for="reset-password-confirmation">{{ $t('users.confirmPasswordLabel') }}</label>
        <BasePassword id="reset-password-confirmation" v-model="resetPasswordForm.password_confirmation" :feedback="false" toggle-mask :invalid="!!resetPasswordErrors.password_confirmation" />
        <small v-if="resetPasswordErrors.password_confirmation" class="field-error">{{ resetPasswordErrors.password_confirmation }}</small>
        <BaseMessage v-if="resetPasswordErrors._root" severity="error" :closable="false">{{ resetPasswordErrors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('users.resetPasswordButton')" :loading="resettingPassword" />
      </form>
    </BaseDialog>
  </div>
</template>

<style scoped>
.create-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field-error {
  color: var(--p-red-500, #ef4444);
  font-size: 0.8125rem;
}
</style>
