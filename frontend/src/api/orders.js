import { apiFetch, apiDownload } from '@/lib/api'
import { OrderSchema, OrderListSchema } from '@/models/order'

const BASE = '/api/v1/admin/orders'

export function listOrders({ customerExternalId, token, projectId } = {}) {
  const path = customerExternalId ? `${BASE}?customer_external_id=${encodeURIComponent(customerExternalId)}` : BASE
  return apiFetch(path, { token, projectId }).then((data) => OrderListSchema.parse(data).orders)
}

export function getOrder(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => OrderSchema.parse(data))
}

export function cancelOrder(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}/cancel`, { method: 'POST', token, projectId, body: input }).then((data) => OrderSchema.parse(data))
}

export function exportOrders({ token, projectId }) {
  return apiDownload(`${BASE}/export`, { token, projectId, filename: 'orders.csv' })
}
