<script setup>
import { useAuthStore } from '@/stores/auth'
import AppShell from '@/components/AppShell.vue'
import BaseCard from '@/components/base/BaseCard.vue'

const auth = useAuthStore()
</script>

<template>
  <AppShell>
    <h1>{{ auth.user ? $t('dashboard.welcomeBackName', { name: auth.user.name }) : $t('dashboard.welcomeBack') }}</h1>
    <BaseCard>
      <template #title>{{ $t('dashboard.signedInAs') }}</template>
      <template #content>
        <dl class="details">
          <dt>{{ $t('dashboard.projectLabel') }}</dt>
          <dd>{{ auth.project?.name }}</dd>
          <dt>{{ $t('dashboard.userLabel') }}</dt>
          <dd>{{ auth.user?.email }}</dd>
          <dt>{{ $t('dashboard.roleLabel') }}</dt>
          <dd>{{ auth.role }}</dd>
        </dl>
      </template>
    </BaseCard>
  </AppShell>
</template>
