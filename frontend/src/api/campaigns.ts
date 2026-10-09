import { apiFetch, type AuthParams } from '@/lib/api'
import { CampaignSchema, CampaignListSchema, type CampaignInput } from '@/models/campaign'

const BASE = '/api/v1/admin/campaigns'

interface ListCampaignsParams extends AuthParams {
  includeArchived?: boolean
  perPage?: number
}

export function listCampaigns({ includeArchived, perPage, token, projectId }: ListCampaignsParams = {}) {
  const params = new URLSearchParams()
  if (includeArchived) params.set('include_archived', 'true')
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => CampaignListSchema.parse(data).campaigns)
}

export function getCampaign(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => CampaignSchema.parse(data))
}

export function createCampaign(input: CampaignInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CampaignSchema.parse(data))
}

export function updateCampaign(id: string, input: Partial<CampaignInput> & { archived?: boolean }, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => CampaignSchema.parse(data))
}

export function duplicateCampaign(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/duplicate`, { method: 'POST', token, projectId }).then((data) => CampaignSchema.parse(data))
}
