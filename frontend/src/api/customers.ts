import { apiFetch, type AuthParams } from '@/lib/api'
import { CustomerSchema, CustomerListSchema, CustomerDetailSchema, type CustomerInput, type GrantPointsInput, type Customer } from '@/models/customer'
import type { PaginatedResult } from '@/models/pagination'

const BASE = '/api/v1/admin/customers'

interface ListCustomersParams extends AuthParams {
  q?: string
  page?: number
  perPage?: number
  includes?: string[]
}

export function listCustomers({ q, page, perPage, includes, token, projectId }: ListCustomersParams = {}): Promise<PaginatedResult<Customer>> {
  const params = new URLSearchParams()
  if (q) params.set('q', q)
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  if (includes?.length) params.set('includes', includes.join(','))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => {
    const parsed = CustomerListSchema.parse(data)
    return { items: parsed.customers, meta: parsed.meta }
  })
}

export function getCustomer(id: string, { includes, token, projectId }: AuthParams & { includes?: string[] }) {
  const query = includes?.length ? `?includes=${includes.join(',')}` : ''
  return apiFetch(`${BASE}/${id}${query}`, { token, projectId }).then((data) => CustomerDetailSchema.parse(data))
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

export function grantPoints(id: string, input: GrantPointsInput, { includes, token, projectId }: AuthParams & { includes?: string[] }) {
  const query = includes?.length ? `?includes=${includes.join(',')}` : ''
  return apiFetch(`${BASE}/${id}/grant_points${query}`, { method: 'POST', token, projectId, body: input }).then(
    (data) => CustomerDetailSchema.parse(data)
  )
}
