<script setup>
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import BaseTag from '@/components/base/BaseTag.vue'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/auth'
import { apiDownload } from '@/lib/api'
import { useAsync } from '@/composables/useAsync'
import { listCustomers } from '@/api/customers'
import { useBaseToast } from '@/composables/useBaseToast.js'
import { formatDateTime } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const { data: customers, loading, error } = useAsync(() => listCustomers({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('customers.loadError'), detail: e.message, life: 4000 })
})

const exporting = ref(false)

const columns = computed(() => [
  { field: 'external_id', header: t('customers.externalId'), sortable: true, hideable: false },
  { field: 'name', header: t('customers.name'), sortable: true },
  { field: 'email', header: t('customers.email'), sortable: true },
  { field: 'membership', header: t('customers.membership') },
  { field: 'country', header: t('customers.country'), sortable: true },
  {
    field: 'marketing_opt_in',
    header: t('customers.marketingOptIn'),
    sortable: true,
    filterOptions: [
      { label: t('customerDetail.details.yes'), value: true },
      { label: t('customerDetail.details.no'), value: false },
    ],
  },
  { field: 'created_at', header: t('customers.created'), sortable: true },
])

function viewCustomer(customer) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}

async function exportCustomers() {
  exporting.value = true
  try {
    await apiDownload('/api/v1/admin/customers/export', { token: auth.token, projectId: auth.project?.id, filename: 'customers.csv' })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('customers.exportError'), detail: e.message, life: 4000 })
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader>
      <template #actions>
        <BaseButton text :label="$t('customers.exportButton')" :loading="exporting" @click="exportCustomers" />
      </template>
    </PageHeader>

    <BaseTable
      :data="customers || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('customers.searchPlaceholder')"
      @row-click="viewCustomer($event.data)"
    >
      <template #cell-membership="{ data }">
        <BaseTag v-if="data.membership_tier" severity="success" :value="`${data.membership_tier.membership_scheme.name} — ${data.membership_tier.name}`" />
        <span v-else class="no-membership">{{ $t('customers.noMembership') }}</span>
      </template>
      <template #cell-marketing_opt_in="{ data }">{{ data.marketing_opt_in ? $t('customerDetail.details.yes') : $t('customerDetail.details.no') }}</template>
      <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at) }}</template>
    </BaseTable>
  </AppShell>
</template>

<style scoped>
.no-membership {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}
</style>
