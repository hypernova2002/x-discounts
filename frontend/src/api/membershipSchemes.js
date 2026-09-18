import { apiFetch } from '@/lib/api'
import { MembershipSchemeSchema, MembershipSchemeListSchema } from '@/models/membershipScheme'
import { MembershipTierSchema } from '@/models/membershipTier'

const BASE = '/api/v1/admin/membership_schemes'

export function listMembershipSchemes({ perPage, token, projectId } = {}) {
  const path = perPage ? `${BASE}?per_page=${perPage}` : BASE
  return apiFetch(path, { token, projectId }).then((data) => MembershipSchemeListSchema.parse(data).membership_schemes)
}

export function getMembershipScheme(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => MembershipSchemeSchema.parse(data))
}

export function createMembershipScheme(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => MembershipSchemeSchema.parse(data))
}

export function updateMembershipScheme(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => MembershipSchemeSchema.parse(data))
}

export function createMembershipTier(schemeId, input, { token, projectId }) {
  return apiFetch(`${BASE}/${schemeId}/tiers`, { method: 'POST', token, projectId, body: input }).then((data) => MembershipTierSchema.parse(data))
}

export function updateMembershipTier(schemeId, tierId, input, { token, projectId }) {
  return apiFetch(`${BASE}/${schemeId}/tiers/${tierId}`, { method: 'PATCH', token, projectId, body: input }).then((data) => MembershipTierSchema.parse(data))
}

export function evaluateMembershipSchemes({ token, projectId }) {
  return apiFetch(`${BASE}/evaluate`, { method: 'POST', token, projectId })
}
