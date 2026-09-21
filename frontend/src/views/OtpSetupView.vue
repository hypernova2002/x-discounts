<script setup>
import { useRouter, useRoute } from 'vue-router'
import BaseCard from '@/components/base/BaseCard.vue'
import OtpEnrollment from '@/components/OtpEnrollment.vue'

// Forced interstitial — the account requires OTP and this user hasn't
// enrolled yet (see router/index.js's beforeEach guard). Not AppShell-wrapped,
// matching SelectProjectView.vue's own forced-onboarding-step precedent.
const router = useRouter()
const route = useRoute()

function onEnabled() {
  router.push(route.query.redirect || { name: 'dashboard' })
}
</script>

<template>
  <div class="auth-page">
    <BaseCard class="setup-card">
      <template #title>{{ $t('otpEnrollment.setupTitle') }}</template>
      <template #subtitle>{{ $t('otpEnrollment.setupSubtitle') }}</template>
      <template #content>
        <OtpEnrollment @enabled="onEnabled" />
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

.setup-card {
  width: 26rem;
}
</style>
