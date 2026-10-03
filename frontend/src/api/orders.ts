import { apiFetch, apiDownload, type AuthParams } from '@/lib/api'
import { OrderSchema, OrderListSchema, type OrderCancelInput } from '@/models/order'

const BASE = '/api/v1/admin/orders'

interface ListOrdersParams extends AuthParams {
  customerExternalId?: string
  perPage?: number
}

export function listOrders({ customerExternalId, perPage, token, projectId }: ListOrdersParams = {}) {
  const params = new URLSearchParams()
  if (customerExternalId) params.set('customer_external_id', customerExternalId)
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => OrderListSchema.parse(data).orders)
}

export function getOrder(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => OrderSchema.parse(data))
}

export function cancelOrder(id: string, input: OrderCancelInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/cancel`, { method: 'POST', token, projectId, body: input }).then((data) => OrderSchema.parse(data))
}

export function exportOrders({ token, projectId }: AuthParams) {
  return apiDownload(`${BASE}/export`, { token, projectId, filename: 'orders.csv' })
}
