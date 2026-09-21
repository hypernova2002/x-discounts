<script setup>
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import QRCode from 'qrcode'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BasePassword from '@/components/base/BasePassword.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import { useAuthStore } from '@/stores/auth'
import { ApiError } from '@/lib/api'
import { setupOtp, enableOtp, disableOtp } from '@/api/me'
import { otpCodeInputSchema } from '@/models/user'
import { toFieldErrors } from '@/models/formErrors'
import { useBaseToast } from '@/composables/useBaseToast'

// Mountable section (no AppShell) — used both by OtpSetupView.vue (the forced,
// account-requires-OTP interstitial) and UserSettingsView.vue (voluntary), so
// the enroll flow exists in exactly one place.
const emit = defineEmits(['enabled'])

const auth = useAuthStore()
const toast = useBaseToast()
const { t } = useI18n()

// idle -> provisioning (QR + code confirm) -> backupCodes (shown once) -> enabled
const status = ref(auth.user?.otp_enabled ? 'enabled' : 'idle')
const qrDataUrl = ref('')
const secret = ref('')
const code = ref('')
const backupCodes = ref([])
const errors = ref({})
const submitting = ref(false)

async function startSetup() {
  errors.value = {}
  submitting.value = true
  try {
    const data = await setupOtp({ token: auth.token, projectId: auth.project?.id })
    secret.value = data.secret
    qrDataUrl.value = await QRCode.toDataURL(data.provisioning_uri)
    status.value = 'provisioning'
  } catch (e) {
    toast.add({ severity: 'error', summary: t('otpEnrollment.setupError'), detail: e.message, life: 4000 })
  } finally {
    submitting.value = false
  }
}

async function confirmCode() {
  errors.value = {}

  const result = otpCodeInputSchema(t).safeParse({ code: code.value })
  if (!result.success) {
    errors.value = toFieldErrors(result.error)
    return
  }

  submitting.value = true
  try {
    const data = await enableOtp(result.data, { token: auth.token, projectId: auth.project?.id })
    auth.user = { ...auth.user, otp_enabled: true }
    backupCodes.value = data.backup_codes
    status.value = 'backupCodes'
  } catch (e) {
    errors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('otpEnrollment.genericError') }
  } finally {
    submitting.value = false
  }
}

function acknowledgeBackupCodes() {
  status.value = 'enabled'
  emit('enabled')
}

const disabling = ref(false)
const disablePassword = ref('')
const disableErrors = ref({})

async function confirmDisable() {
  disableErrors.value = {}

  if (!disablePassword.value) {
    disableErrors.value = { current_password: t('otpEnrollment.currentPasswordRequired') }
    return
  }

  submitting.value = true
  try {
    await disableOtp({ current_password: disablePassword.value }, { token: auth.token, projectId: auth.project?.id })
    auth.user = { ...auth.user, otp_enabled: false }
    status.value = 'idle'
    disabling.value = false
    disablePassword.value = ''
    toast.add({ severity: 'success', summary: t('otpEnrollment.disabledSuccess'), life: 3000 })
  } catch (e) {
    disableErrors.value = e instanceof ApiError ? toFieldErrors(e) : { _root: t('otpEnrollment.genericError') }
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  if (status.value === 'idle') startSetup()
})
</script>

<template>
  <div class="otp-enrollment">
    <template v-if="status === 'idle'">
      <p class="hint">{{ $t('otpEnrollment.idleHint') }}</p>
      <BaseButton :label="$t('otpEnrollment.enableButton')" :loading="submitting" @click="startSetup" />
    </template>

    <template v-else-if="status === 'provisioning'">
      <p class="hint">{{ $t('otpEnrollment.scanHint') }}</p>
      <img v-if="qrDataUrl" :src="qrDataUrl" :alt="$t('otpEnrollment.qrAlt')" class="qr-code" />
      <p class="secret-hint">{{ $t('otpEnrollment.manualEntryHint') }}</p>
      <code class="secret">{{ secret }}</code>
      <form class="confirm-form" @submit.prevent="confirmCode">
        <label for="otp-confirm-code">{{ $t('otpEnrollment.codeLabel') }}</label>
        <BaseInputText id="otp-confirm-code" v-model="code" autocomplete="one-time-code" :invalid="!!errors.code" />
        <small v-if="errors.code" class="field-error">{{ errors.code }}</small>
        <BaseMessage v-if="errors._root" severity="error" :closable="false">{{ errors._root }}</BaseMessage>
        <BaseButton type="submit" :label="$t('otpEnrollment.confirmButton')" :loading="submitting" />
      </form>
    </template>

    <template v-else-if="status === 'backupCodes'">
      <BaseMessage severity="warn" :closable="false">{{ $t('otpEnrollment.backupCodesWarning') }}</BaseMessage>
      <ul class="backup-codes">
        <li v-for="c in backupCodes" :key="c">{{ c }}</li>
      </ul>
      <BaseButton :label="$t('otpEnrollment.savedCodesButton')" @click="acknowledgeBackupCodes" />
    </template>

    <template v-else-if="status === 'enabled'">
      <BaseMessage severity="success" :closable="false">{{ $t('otpEnrollment.enabledStatus') }}</BaseMessage>
      <template v-if="!auth.otpRequired">
        <BaseButton v-if="!disabling" outlined :label="$t('otpEnrollment.disableButton')" @click="disabling = true" />
        <form v-else class="confirm-form" @submit.prevent="confirmDisable">
          <label for="otp-disable-password">{{ $t('otpEnrollment.currentPasswordLabel') }}</label>
          <BasePassword id="otp-disable-password" v-model="disablePassword" :feedback="false" toggle-mask :invalid="!!disableErrors.current_password" />
          <small v-if="disableErrors.current_password" class="field-error">{{ disableErrors.current_password }}</small>
          <BaseMessage v-if="disableErrors._root" severity="error" :closable="false">{{ disableErrors._root }}</BaseMessage>
          <div class="disable-actions">
            <BaseButton type="submit" severity="danger" :label="$t('otpEnrollment.disableButton')" :loading="submitting" />
            <BaseButton text :label="$t('otpEnrollment.cancelButton')" @click="disabling = false" />
          </div>
        </form>
      </template>
      <p v-else class="hint">{{ $t('otpEnrollment.requiredHint') }}</p>
    </template>
  </div>
</template>

<style scoped>
.otp-enrollment {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-width: 24rem;
}

.hint,
.secret-hint {
  margin: 0;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.qr-code {
  width: 12rem;
  height: 12rem;
  align-self: flex-start;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.5rem;
}

.secret {
  align-self: flex-start;
  padding: 0.375rem 0.625rem;
  background: var(--color-bg-subtle);
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  letter-spacing: 0.05em;
}

.confirm-form {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.field-error {
  color: var(--color-danger);
  font-size: 0.8125rem;
}

.backup-codes {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.5rem;
  margin: 0;
  padding: 0.75rem 1rem;
  background: var(--color-bg-subtle);
  border-radius: var(--radius-sm);
  list-style: none;
  font-variant-numeric: tabular-nums;
  font-size: 0.875rem;
}

.disable-actions {
  display: flex;
  gap: 0.5rem;
}
</style>
