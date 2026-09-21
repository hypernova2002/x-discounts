<script setup>
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppShell from '@/components/AppShell.vue'
import PageHeader from '@/components/PageHeader.vue'
import EntityLink from '@/components/EntityLink.vue'
import BaseTable from '@/components/base/BaseTable.vue'
import { useAuthStore } from '@/stores/auth'
import { useAsync } from '@/composables/useAsync'
import { listOrders, exportOrders as exportOrdersRequest } from '@/api/orders'
import { useBaseToast } from '@/composables/useBaseToast'
import { formatNumber, formatDateTime } from '@/lib/format'

const auth = useAuthStore()
const toast = useBaseToast()
const router = useRouter()
const { t } = useI18n()

const exporting = ref(false)

const { data: orders, loading, error, reload } = useAsync(() => listOrders({ token: auth.token, projectId: auth.project?.id }))

watch(error, (e) => {
  if (e) toast.add({ severity: 'error', summary: t('orders.loadError'), detail: e.message, life: 4000 })
})

const columns = computed(() => [
  { field: 'id', header: t('orders.order'), sortable: true, hideable: false, filter: { type: 'string' } },
  { field: 'customer', header: t('orders.customer'), hideable: false, filter: { type: 'string', accessor: (row) => row.customer.external_id } },
  { field: 'line_items', header: t('orders.items'), filter: { type: 'number', accessor: (row) => row.line_items.length } },
  { field: 'total_amount', header: t('orders.total'), sortable: true, filter: { type: 'number' } },
  { field: 'total_discount_amount', header: t('orders.discount'), sortable: true, filter: { type: 'number' } },
  { field: 'created_at', header: t('orders.created'), sortable: true, filter: { type: 'date' } },
])

function createOrder() {
  router.push({ name: 'order-new' })
}

function viewOrder(order) {
  router.push({ name: 'order-show', params: { id: order.id } })
}

function viewCustomer(customer) {
  router.push({ name: 'customer-show', params: { id: customer.id } })
}

async function exportOrders() {
  exporting.value = true
  try {
    await exportOrdersRequest({ token: auth.token, projectId: auth.project?.id })
  } catch (e) {
    toast.add({ severity: 'error', summary: t('orders.exportError'), detail: e.message, life: 4000 })
  } finally {
    exporting.value = false
  }
}
</script>

<template>
  <AppShell>
    <PageHeader />

    <BaseTable
      :data="orders || []"
      :columns="columns"
      :loading="loading"
      row-key="id"
      :search-placeholder="$t('orders.searchPlaceholder')"
      :create-label="$t('orders.newOrder')"
      :export-label="$t('orders.exportButton')"
      :exporting="exporting"
      @row-click="viewOrder($event.data)"
      @refresh="reload"
      @create="createOrder"
      @export="exportOrders"
    >
      <template #cell-customer="{ data }">
        <EntityLink @click="viewCustomer(data.customer)">{{ data.customer.external_id }}</EntityLink>
      </template>
      <template #cell-line_items="{ data }">{{ data.line_items.length }}</template>
      <template #cell-total_amount="{ data }">{{ formatNumber(data.total_amount) }}</template>
      <template #cell-total_discount_amount="{ data }">{{ formatNumber(data.total_discount_amount) }}</template>
      <template #cell-created_at="{ data }">{{ formatDateTime(data.created_at, auth.project?.timezone) }}</template>
    </BaseTable>
  </AppShell>
</template>
