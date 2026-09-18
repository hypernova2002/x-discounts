<script setup>
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listMembershipSchemes } from '@/api/membershipSchemes'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatDate } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { data: schemes, loading, error, reload } = useAsync(() => listMembershipSchemes({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('membershipSchemes.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'name', header: t('membershipSchemes.columns.name'), sortable: true, hideable: false },
  { field: 'tiers', header: t('membershipSchemes.columns.tiers') },
  { field: 'created_at', header: t('membershipSchemes.columns.created'), sortable: true },
])

function createScheme() {
  router.push({ name: 'membership-scheme-new' })
}

function viewScheme(scheme) {
  router.push({ name: 'membership-scheme-show', params: { id: scheme.id } })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <BaseButton :label="$t('membershipSchemes.newSchemeButton')" @click="createScheme" />
      </template>
    </PageHeader>

    <BaseTable
      :data="schemes || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('membershipSchemes.searchPlaceholder')"
      @row-click="viewScheme($event.data)"
      @refresh="reload"
    >
      <template #cell-tiers="{ data }">{{ data.tiers.map((tier) => tier.name).join(', ') || '—' }}</template>
      <template #cell-created_at="{ data }">{{ formatDate(data.created_at) }}</template>
    </BaseTable>
  </AppShell>
</template>

