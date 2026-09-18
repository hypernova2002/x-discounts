<script setup>
import { reactive } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import BaseInputText from '@/components/base/BaseInputText.vue'
import BasePassword from '@/components/base/BasePassword.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'
import BaseCard from '@/components/base/BaseCard.vue'

const form = reactive({
  account_name: '',
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
})
const auth = useAuthStore()
const router = useRouter()

async function submit() {
  try {
    await auth.signup({ ...form })
    router.push({ name: 'dashboard' })
  } catch {
    // error is surfaced via auth.error in the template
  }
}
</script>

<template>
  <div class="auth-page">
    <BaseCard class="auth-card">
      <template #title>{{ $t('signup.appName') }}</template>
      <template #subtitle>{{ $t('signup.subtitle') }}</template>
      <template #content>
        <form class="auth-form" @submit.prevent="submit">
          <label for="account_name">{{ $t('signup.accountNameLabel') }}</label>
          <BaseInputText id="account_name" v-model="form.account_name" autofocus />
          <label for="name">{{ $t('signup.nameLabel') }}</label>
          <BaseInputText id="name" v-model="form.name" />
          <label for="email">{{ $t('signup.emailLabel') }}</label>
          <BaseInputText id="email" v-model="form.email" type="email" />
          <label for="password">{{ $t('signup.passwordLabel') }}</label>
          <BasePassword id="password" v-model="form.password" :feedback="false" toggle-mask />
          <label for="password_confirmation">{{ $t('signup.passwordConfirmationLabel') }}</label>
          <BasePassword id="password_confirmation" v-model="form.password_confirmation" :feedback="false" toggle-mask />
          <BaseMessage v-if="auth.error" severity="error" :closable="false">{{ auth.error }}</BaseMessage>
          <BaseButton type="submit" :label="$t('signup.submitButton')" :loading="auth.loading" />
          <RouterLink class="auth-link" to="/login">{{ $t('signup.loginLink') }}</RouterLink>
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
  width: 26rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.auth-link {
  text-align: center;
  font-size: 0.875rem;
  color: var(--p-primary-color, #10b981);
}
</style>
