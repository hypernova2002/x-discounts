<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import type { TableColumn } from '@/components/base/BaseTable.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listMembershipSchemes } from '@/api/membershipSchemes'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatDate } from '@/lib/format'
import type { MembershipScheme } from '@/models/membershipScheme'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const page = ref(1)
const perPage = ref(25)
const q = ref('')

const { data: result, loading, error, reload } = useAsync(() =>
  listMembershipSchemes({
    q: q.value || undefined,
    page: page.value,
    perPage: perPage.value,
    includes: ['membership_tiers'],
    token: auth.token ?? undefined,
    projectId: auth.project?.id,
  })
)
const schemes = computed(() => result.value?.items ?? [])
const meta = computed(() => result.value?.meta)

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('membershipSchemes.loadError'), detail: e instanceof Error ? e.message : String(e), life: 4000 })
})

function onPage(event: { page: number; rows: number }) {
  page.value = event.page
  perPage.value = event.rows
  reload()
}

function onSearch(value: string) {
  q.value = value
  page.value = 1
  reload()
}

const columns = computed<TableColumn[]>(() => [
  { field: 'name', header: t('membershipSchemes.columns.name'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'tiers', header: t('membershipSchemes.columns.tiers'), filter: { type: 'number', accessor: (row) => (row as unknown as MembershipScheme).tiers?.length ?? 0 } },
  { field: 'created_at', header: t('membershipSchemes.columns.created'), sortable: true, filter: { type: 'date' } },
])

function createScheme() {
  router.push({ name: 'membership-scheme-new' })
}

function viewScheme(scheme: MembershipScheme) {
  router.push({ name: 'membership-scheme-show', params: { id: scheme.id } })
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #title>
        <BaseButton icon="pi pi-plus" :label="t('membershipSchemes.newSchemeButton')" @click="createScheme" />
      </template>
    </PageHeader>

    <BaseCard class="section-card">
      <template #content>
        <BaseTable
          :data="schemes"
          :columns="columns"
          :loading="loading"
          row-key="id"
          lazy
          :total-records="meta?.count ?? 0"
          :search-placeholder="$t('membershipSchemes.searchPlaceholder')"
          @row-click="viewScheme($event.data as unknown as MembershipScheme)"
          @refresh="reload"
          @page="onPage"
          @search="onSearch"
        >
          <template #cell-tiers="{ data }">{{ (data.tiers ?? []).map((tier: { name: string }) => tier.name).join(', ') || '—' }}</template>
          <template #cell-created_at="{ data }">{{ formatDate(data.created_at, auth.project?.timezone) }}</template>
        </BaseTable>
      </template>
    </BaseCard>
  </AppShell>
</template>

