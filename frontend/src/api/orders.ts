import { apiFetch, type AuthParams } from '@/lib/api'
import { OrderSchema, OrderListSchema, type OrderCancelInput, type Order } from '@/models/order'
import type { PaginatedResult } from '@/models/pagination'

const BASE = '/api/v1/admin/orders'

interface ListOrdersParams extends AuthParams {
  customerExternalId?: string
  q?: string
  page?: number
  perPage?: number
}

export function listOrders({ customerExternalId, q, page, perPage, token, projectId }: ListOrdersParams = {}): Promise<PaginatedResult<Order>> {
  const params = new URLSearchParams()
  if (customerExternalId) params.set('customer_external_id', customerExternalId)
  if (q) params.set('q', q)
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => {
    const parsed = OrderListSchema.parse(data)
    return { items: parsed.orders, meta: parsed.meta }
  })
}

export function getOrder(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => OrderSchema.parse(data))
}

export function cancelOrder(id: string, input: OrderCancelInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/cancel`, { method: 'POST', token, projectId, body: input }).then((data) => OrderSchema.parse(data))
}
