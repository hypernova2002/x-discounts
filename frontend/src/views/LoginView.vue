<script setup>
import { ref } from 'vue'
import { useRouter, useRoute, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BasePassword from '@/components/base/BasePassword.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseCard from '@/components/base/BaseCard.vue'

const email = ref('')
const password = ref('')
const code = ref('')
const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

async function submit() {
  try {
    await auth.login(email.value.trim(), password.value)
    if (!auth.otpChallengeToken) router.push(route.query.redirect || { name: 'dashboard' })
  } catch {
    // error is surfaced via auth.error in the template
  }
}

async function submitOtp() {
  try {
    await auth.verifyOtp(code.value.trim())
    router.push(route.query.redirect || { name: 'dashboard' })
  } catch {
    // error is surfaced via auth.error in the template
  }
}

function backToLogin() {
  auth.otpChallengeToken = null
  auth.error = null
  password.value = ''
  code.value = ''
}
</script>

<template>
  <div class="auth-page">
    <BaseCard class="auth-card">
      <template v-if="!auth.otpChallengeToken" #title>{{ $t('login.appName') }}</template>
      <template v-if="!auth.otpChallengeToken" #subtitle>{{ $t('login.subtitle') }}</template>
      <template v-else #title>{{ $t('login.otpTitle') }}</template>
      <template #content>
        <form v-if="!auth.otpChallengeToken" class="auth-form" @submit.prevent="submit">
          <label for="email">{{ $t('login.emailLabel') }}</label>
          <BaseInputText id="email" v-model="email" type="email" autofocus />
          <label for="password">{{ $t('login.passwordLabel') }}</label>
          <BasePassword id="password" v-model="password" :feedback="false" toggle-mask />
          <BaseMessage v-if="auth.error" severity="error" :closable="false">{{ auth.error }}</BaseMessage>
          <BaseButton type="submit" :label="$t('login.submitButton')" :loading="auth.loading" />
          <RouterLink class="auth-link" to="/signup">{{ $t('login.signupLink') }}</RouterLink>
        </form>
        <form v-else class="auth-form" @submit.prevent="submitOtp">
          <p class="auth-hint">{{ $t('login.otpHint') }}</p>
          <label for="otp-code">{{ $t('login.otpCodeLabel') }}</label>
          <BaseInputText id="otp-code" v-model="code" autofocus autocomplete="one-time-code" />
          <BaseMessage v-if="auth.error" severity="error" :closable="false">{{ auth.error }}</BaseMessage>
          <BaseButton type="submit" :label="$t('login.otpSubmitButton')" :loading="auth.loading" />
          <button type="button" class="auth-link auth-link--button" @click="backToLogin">
            {{ $t('login.backToLoginLink') }}
          </button>
        </form>
      </template>
    </BaseCard>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--p-content-background, #f4f4f5);
}

.auth-card {
  width: 24rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.auth-hint {
  margin: 0;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.auth-link {
  text-align: center;
  font-size: 0.875rem;
  color: var(--p-primary-color, #10b981);
}

.auth-link--button {
  background: none;
  border: none;
  cursor: pointer;
  font: inherit;
}
</style>
