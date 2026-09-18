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
const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

async function submit() {
  try {
    await auth.login(email.value.trim(), password.value)
    router.push(route.query.redirect || { name: 'dashboard' })
  } catch {
    // error is surfaced via auth.error in the template
  }
}
</script>

<template>
  <div class="auth-page">
    <BaseCard class="auth-card">
      <template #title>{{ $t('login.appName') }}</template>
      <template #subtitle>{{ $t('login.subtitle') }}</template>
      <template #content>
        <form class="auth-form" @submit.prevent="submit">
          <label for="email">{{ $t('login.emailLabel') }}</label>
          <BaseInputText id="email" v-model="email" type="email" autofocus />
          <label for="password">{{ $t('login.passwordLabel') }}</label>
          <BasePassword id="password" v-model="password" :feedback="false" toggle-mask />
          <BaseMessage v-if="auth.error" severity="error" :closable="false">{{ auth.error }}</BaseMessage>
          <BaseButton type="submit" :label="$t('login.submitButton')" :loading="auth.loading" />
          <RouterLink class="auth-link" to="/signup">{{ $t('login.signupLink') }}</RouterLink>
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

.auth-link {
  text-align: center;
  font-size: 0.875rem;
  color: var(--p-primary-color, #10b981);
}
</style>
