<script setup>
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { AVAILABLE_LOCALES } from '@/i18n'
import { NAV_SECTIONS, findSection } from '@/lib/navSections'
import { useBaseToast } from '@/composables/useBaseToast'
import BaseMenu from '@/components/base/BaseMenu.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseSelect from '@/components/base/BaseSelect.vue'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const toast = useBaseToast()
const { t } = useI18n()

const sidebarOpen = ref(false)

function go(name) {
  router.push({ name })
  sidebarOpen.value = false
}

function toMenuItem(section) {
  return { label: t(section.labelKey), icon: section.icon, routeNames: section.routeNames, command: () => go(section.to.name) }
}

const navItems = computed(() => [
  ...NAV_SECTIONS.filter((s) => !s.group).map(toMenuItem),
  { separator: true },
  { label: t('nav.admin'), items: NAV_SECTIONS.filter((s) => s.group === 'admin').map(toMenuItem) },
  { label: t('nav.account'), items: NAV_SECTIONS.filter((s) => s.group === 'account').map(toMenuItem) },
])

const currentSection = computed(() => findSection(route.name))

const currentLocale = computed(() => AVAILABLE_LOCALES.find((l) => l.code === auth.user?.locale) || AVAILABLE_LOCALES[0])

async function logout() {
  await auth.logout()
  router.push({ name: 'login' })
}

const switchingProject = ref(false)

async function switchProject(projectId) {
  if (!projectId || projectId === auth.project?.id) return
  switchingProject.value = true
  try {
    await auth.selectProject(projectId)
    // Whatever the current page is now likely refers to data scoped to the
    // previous project (a specific campaign/customer/etc. by id) — land
    // somewhere always valid instead of risking a 404 on the new project.
    router.push({ name: 'dashboard' })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('nav.switchProjectError'), detail: e.message, life: 4000 })
  } finally {
    switchingProject.value = false
  }
}

onMounted(() => {
  if (auth.user) auth.fetchProjects().catch(() => {})
})
</script>

<template>
  <div class="app-shell">
    <header class="app-shell__topbar">
      <div class="app-shell__topbar-start">
        <button
          type="button"
          class="app-shell__nav-toggle"
          :aria-label="t('nav.toggleMenu')"
          @click="sidebarOpen = !sidebarOpen"
        >
          <i class="pi pi-bars" />
        </button>
        <RouterLink :to="{ name: 'dashboard' }" class="app-shell__brand">x-discounts</RouterLink>
        <template v-if="currentSection && currentSection.id !== 'dashboard'">
          <span class="app-shell__section-divider" aria-hidden="true">/</span>
          <h1 class="app-shell__section">{{ t(currentSection.labelKey) }}</h1>
        </template>
      </div>
      <div class="app-shell__topbar-end">
        <BaseSelect
          v-if="auth.user"
          :model-value="auth.user.locale"
          :options="AVAILABLE_LOCALES"
          option-label="label"
          option-value="code"
          :aria-label="t('nav.language')"
          class="app-shell__locale"
          @update:model-value="auth.updateLocale"
        >
          <template #value>
            <span class="app-shell__locale-value">
              <i class="pi pi-language" />
              <span aria-hidden="true">{{ currentLocale.flag }}</span>
            </span>
          </template>
          <template #option="{ option }">
            <span class="app-shell__locale-option">
              <span aria-hidden="true">{{ option.flag }}</span>
              {{ option.label }}
            </span>
          </template>
        </BaseSelect>
        <BaseTag v-if="auth.role" :value="auth.role" class="app-shell__role-tag" />
        <BaseSelect
          v-if="auth.project"
          :model-value="auth.project.id"
          :options="auth.projects"
          option-label="name"
          option-value="id"
          filter
          :loading="switchingProject"
          :aria-label="t('nav.switchProject')"
          class="app-shell__project"
          @update:model-value="switchProject"
        />
        <BaseTag
          v-if="auth.project?.timezone"
          :value="auth.project.timezone"
          v-tooltip.bottom="t('nav.projectTimezoneTooltip')"
          class="app-shell__timezone-tag"
        />
        <BaseButton text :label="t('nav.signOut')" @click="logout" />
      </div>
    </header>

    <div class="app-shell__body">
      <div v-if="sidebarOpen" class="app-shell__sidebar-backdrop" @click="sidebarOpen = false" />
      <nav class="app-shell__sidebar" :class="{ 'app-shell__sidebar--open': sidebarOpen }">
        <BaseMenu :model="navItems" :aria-label="t('nav.dashboard')" />
      </nav>
      <main class="app-shell__content">
        <slot />
      </main>
    </div>
  </div>
</template>

<style scoped>
.app-shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.app-shell__topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  height: 3.5rem;
  padding: 0 1rem;
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg);
}

.app-shell__topbar-start {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.app-shell__nav-toggle {
  display: none;
  align-items: center;
  justify-content: center;
  height: 2.25rem;
  width: 2.25rem;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: var(--color-text);
  cursor: pointer;
}

.app-shell__nav-toggle:hover {
  background: var(--color-bg-subtle);
}

.app-shell__brand {
  font-weight: 600;
  font-size: 0.875rem;
  color: var(--color-text-muted);
  text-decoration: none;
}

.app-shell__brand:hover {
  color: var(--color-text);
}

.app-shell__section-divider {
  color: var(--color-border);
  font-size: 1.125rem;
  line-height: 1;
}

.app-shell__section {
  margin: 0;
  font-size: 1.0625rem;
  font-weight: 500;
  color: var(--color-text);
  line-height: 1;
}

.app-shell__topbar-end {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.app-shell__project {
  /* Overrides BaseSelect's default w-full — inside this flex row that would
     otherwise be read as the item's flex-basis and push everything else out
     (the same width:100%-in-a-flex-row trap fixed elsewhere in this app).
     Plain scoped CSS beats a Tailwind utility class regardless of source
     order (Tailwind utilities live in @layer utilities; this rule doesn't). */
  width: auto;
  max-width: 11rem;
}

.app-shell__locale {
  width: auto;
}

.app-shell__locale-value {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
}

.app-shell__locale-value .pi-language {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.app-shell__locale-option {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.app-shell__body {
  display: flex;
  flex: 1;
  min-height: 0;
}

.app-shell__sidebar-backdrop {
  display: none;
}

.app-shell__sidebar {
  width: 15rem;
  flex-shrink: 0;
  background: var(--color-bg-subtle);
  border-right: 1px solid var(--color-border);
  padding: 1rem 0.75rem;
  overflow-y: auto;
}

.app-shell__content {
  flex: 1;
  min-width: 0;
  max-width: 960px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

@media (max-width: 900px) {
  .app-shell__nav-toggle {
    display: inline-flex;
  }

  .app-shell__sidebar {
    position: fixed;
    top: 3.5rem;
    left: 0;
    bottom: 0;
    z-index: 40;
    background: var(--color-bg-subtle);
    transform: translateX(-100%);
    transition: transform 0.2s ease;
    box-shadow: var(--shadow-lg);
  }

  .app-shell__sidebar--open {
    transform: translateX(0);
  }

  .app-shell__sidebar-backdrop {
    display: block;
    position: fixed;
    inset: 3.5rem 0 0 0;
    background: rgb(0 0 0 / 40%);
    z-index: 30;
  }
}

@media (max-width: 640px) {
  .app-shell__topbar {
    padding: 0 0.5rem;
    gap: 0.375rem;
  }

  .app-shell__brand {
    font-size: 0.9375rem;
  }

  .app-shell__topbar-end {
    gap: 0.375rem;
  }

  .app-shell__role-tag,
  .app-shell__timezone-tag {
    display: none;
  }
}
</style>
