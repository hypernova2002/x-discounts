import { apiFetch, type AuthParams } from '@/lib/api'
import { MembershipSchemeSchema, MembershipSchemeListSchema, type MembershipSchemeInput, type MembershipScheme } from '@/models/membershipScheme'
import { MembershipTierSchema, type MembershipTierInput } from '@/models/membershipTier'
import type { PaginatedResult } from '@/models/pagination'

const BASE = '/api/v1/admin/membership_schemes'

interface ListMembershipSchemesParams extends AuthParams {
  q?: string
  page?: number
  perPage?: number
  includes?: string[]
}

export function listMembershipSchemes({ q, page, perPage, includes, token, projectId }: ListMembershipSchemesParams = {}): Promise<PaginatedResult<MembershipScheme>> {
  const params = new URLSearchParams()
  if (q) params.set('q', q)
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  if (includes?.length) params.set('includes', includes.join(','))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => {
    const parsed = MembershipSchemeListSchema.parse(data)
    return { items: parsed.membership_schemes, meta: parsed.meta }
  })
}

export function getMembershipScheme(id: string, { includes, token, projectId }: AuthParams & { includes?: string[] }) {
  const query = includes?.length ? `?includes=${includes.join(',')}` : ''
  return apiFetch(`${BASE}/${id}${query}`, { token, projectId }).then((data) => MembershipSchemeSchema.parse(data))
}

export function createMembershipScheme(input: MembershipSchemeInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => MembershipSchemeSchema.parse(data))
}

export function updateMembershipScheme(id: string, input: Partial<MembershipSchemeInput>, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => MembershipSchemeSchema.parse(data))
}

export function createMembershipTier(schemeId: string, input: MembershipTierInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${schemeId}/tiers`, { method: 'POST', token, projectId, body: input }).then((data) => MembershipTierSchema.parse(data))
}

interface UpdateMembershipTierInput extends MembershipTierInput {
  requirements_condition: unknown
  grace_period_days: number | null
}

export function updateMembershipTier(schemeId: string, tierId: string, input: UpdateMembershipTierInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${schemeId}/tiers/${tierId}`, { method: 'PATCH', token, projectId, body: input }).then((data) => MembershipTierSchema.parse(data))
}

interface EvaluateMembershipSchemesResponse {
  evaluated: number
}

export function evaluateMembershipSchemes({ token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/evaluate`, { method: 'POST', token, projectId }) as Promise<EvaluateMembershipSchemesResponse>
}
