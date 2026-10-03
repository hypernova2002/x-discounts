import { apiFetch, type AuthParams } from '@/lib/api'
import { MembershipSchemeSchema, MembershipSchemeListSchema, type MembershipSchemeInput } from '@/models/membershipScheme'
import { MembershipTierSchema, type MembershipTierInput } from '@/models/membershipTier'

const BASE = '/api/v1/admin/membership_schemes'

interface ListMembershipSchemesParams extends AuthParams {
  perPage?: number
}

export function listMembershipSchemes({ perPage, token, projectId }: ListMembershipSchemesParams = {}) {
  const path = perPage ? `${BASE}?per_page=${perPage}` : BASE
  return apiFetch(path, { token, projectId }).then((data) => MembershipSchemeListSchema.parse(data).membership_schemes)
}

export function getMembershipScheme(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => MembershipSchemeSchema.parse(data))
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
