import { apiFetch, type AuthParams } from '@/lib/api'
import { CampaignSchema, CampaignListSchema, type CampaignInput, type Campaign } from '@/models/campaign'
import type { PaginatedResult } from '@/models/pagination'

const BASE = '/api/v1/admin/campaigns'

interface ListCampaignsParams extends AuthParams {
  includeArchived?: boolean
  q?: string
  page?: number
  perPage?: number
}

export function listCampaigns({ includeArchived, q, page, perPage, token, projectId }: ListCampaignsParams = {}): Promise<PaginatedResult<Campaign>> {
  const params = new URLSearchParams()
  if (includeArchived) params.set('include_archived', 'true')
  if (q) params.set('q', q)
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => {
    const parsed = CampaignListSchema.parse(data)
    return { items: parsed.campaigns, meta: parsed.meta }
  })
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
