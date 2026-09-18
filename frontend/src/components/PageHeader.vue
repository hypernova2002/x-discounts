<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { findSection } from '@/lib/navSections'

// The section crumb (e.g. "Customers") and the overall page heading now live
// in AppShell's top bar, computed from the same NAV_SECTIONS lookup — this
// component only adds what the top bar can't know: extra breadcrumb segments
// for an entity reached through a parent that isn't its own sidebar section
// (currently only Discounts, reached via a specific Campaign), and the
// page's own subheading (the #title slot, demoted from <h1> to <h2> — see
// the .page-header__title :deep(h2) rule below). List pages pass no #title
// slot at all, matching the top bar already fully identifying them.
const props = defineProps({
  // Extra crumb segments between the section and this page, e.g. the parent
  // campaign's name for a discount: [{ label, to }]. `to` omitted -> plain text.
  crumbs: { type: Array, default: () => [] },
})

const route = useRoute()
const { t } = useI18n()

const section = computed(() => findSection(route.name))
const isSectionListPage = computed(() => section.value && route.name === section.value.to.name)
const showBreadcrumb = computed(() => section.value && !isSectionListPage.value)
</script>

<template>
  <div class="page-header">
    <nav v-if="showBreadcrumb" class="page-header__breadcrumb" :aria-label="t('pageHeader.breadcrumbLabel')">
      <RouterLink :to="section.to">{{ t(section.labelKey) }}</RouterLink>
      <template v-for="(crumb, i) in crumbs" :key="i">
        <i class="pi pi-angle-right" aria-hidden="true" />
        <RouterLink v-if="crumb.to" :to="crumb.to">{{ crumb.label }}</RouterLink>
        <span v-else>{{ crumb.label }}</span>
      </template>
    </nav>
    <div class="page-header__row">
      <div class="page-header__title">
        <slot name="title" />
      </div>
      <div class="page-header__actions">
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-header {
  margin-bottom: 1.5rem;
}

.page-header__breadcrumb {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  margin-bottom: 0.5rem;
}

.page-header__breadcrumb a {
  color: var(--color-text-muted);
  text-decoration: none;
}

.page-header__breadcrumb a:hover {
  color: var(--color-primary);
  text-decoration: underline;
}

.page-header__breadcrumb .pi-angle-right {
  font-size: 0.625rem;
  color: var(--color-border);
}

.page-header__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.page-header__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.page-header__title :deep(h2) {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--color-text);
}

.page-header__actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
</style>
