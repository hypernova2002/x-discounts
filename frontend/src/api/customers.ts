import { apiFetch, type AuthParams } from '@/lib/api'
import { CustomerSchema, CustomerListSchema, CustomerDetailSchema, type CustomerInput, type GrantPointsInput } from '@/models/customer'

const BASE = '/api/v1/admin/customers'

interface ListCustomersParams extends AuthParams {
  q?: string
  perPage?: number
}

export function listCustomers({ q, perPage, token, projectId }: ListCustomersParams = {}) {
  const params = new URLSearchParams()
  if (q) params.set('q', q)
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then(
    (data) => CustomerListSchema.parse(data).customers
  )
}

export function getCustomer(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => CustomerDetailSchema.parse(data))
}

export function createCustomer(input: CustomerInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CustomerSchema.parse(data))
}

export function duplicateCustomer(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/duplicate`, { method: 'POST', token, projectId }).then((data) => CustomerSchema.parse(data))
}

interface UpdateCustomerInput extends Partial<CustomerInput> {
  // Tri-state (see CustomerUpdateRequest): omit to leave unchanged, null to
  // unassign, or a tier id to assign.
  membership_tier_id?: string | null
}

// The backend's PATCH returns the plain customer shape (no stats/activity/
// loyalty_point_lots) — see CustomerUpdateRequest's tri-state comment for how
// `input` should be built: omit `membership_tier_id` to leave it unchanged,
// pass it as `null` to unassign, or as a tier id to assign.
export function updateCustomer(id: string, input: UpdateCustomerInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => CustomerSchema.parse(data))
}

export function grantPoints(id: string, input: GrantPointsInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/grant_points`, { method: 'POST', token, projectId, body: input }).then(
    (data) => CustomerDetailSchema.parse(data)
  )
}
