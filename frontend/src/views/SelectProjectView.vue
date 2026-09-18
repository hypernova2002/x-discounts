<script setup>
import { onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import BaseCard from '@/components/base/BaseCard.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseMessage from '@/components/base/BaseMessage.vue'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const loading = ref(false)
const error = ref(null)

onMounted(async () => {
  loading.value = true
  try {
    await auth.fetchProjects()
  } catch {
    error.value = t('selectProject.loadError')
  } finally {
    loading.value = false
  }
})

async function choose(project) {
  loading.value = true
  error.value = null
  try {
    await auth.selectProject(project.id)
    router.push(route.query.redirect || { name: 'dashboard' })
  } catch {
    error.value = t('selectProject.selectError')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <BaseCard class="select-card">
      <template #title>{{ $t('selectProject.appName') }}</template>
      <template #subtitle>{{ $t('selectProject.subtitle') }}</template>
      <template #content>
        <BaseMessage v-if="error" severity="error" :closable="false">{{ error }}</BaseMessage>
        <p v-if="!loading && !auth.projects.length">{{ $t('selectProject.noProjects') }}</p>
        <div class="project-list">
          <BaseButton
            v-for="project in auth.projects"
            :key="project.id"
            outlined
            class="project-button"
            :label="project.name"
            :disabled="loading"
            @click="choose(project)"
          />
        </div>
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

.select-card {
  width: 26rem;
}

.project-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.project-button {
  justify-content: flex-start;
}
</style>
