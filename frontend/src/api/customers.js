import { apiFetch } from '@/lib/api'
import { CustomerSchema, CustomerListSchema, CustomerDetailSchema } from '@/models/customer'

const BASE = '/api/v1/admin/customers'

export function listCustomers({ q, perPage, token, projectId } = {}) {
  const params = new URLSearchParams()
  if (q) params.set('q', q)
  if (perPage) params.set('per_page', perPage)
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then(
    (data) => CustomerListSchema.parse(data).customers
  )
}

export function getCustomer(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => CustomerDetailSchema.parse(data))
}

export function createCustomer(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CustomerSchema.parse(data))
}

// The backend's PATCH returns the plain customer shape (no stats/activity/
// loyalty_point_lots) — see CustomerUpdateRequest's tri-state comment for how
// `input` should be built: omit `membership_tier_id` to leave it unchanged,
// pass it as `null` to unassign, or as a tier id to assign.
export function updateCustomer(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => CustomerSchema.parse(data))
}

export function grantPoints(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}/grant_points`, { method: 'POST', token, projectId, body: input }).then(
    (data) => CustomerDetailSchema.parse(data)
  )
}
