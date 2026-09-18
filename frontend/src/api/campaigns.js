import { apiFetch, apiDownload } from '@/lib/api'
import { CampaignSchema, CampaignListSchema } from '@/models/campaign'

const BASE = '/api/v1/admin/campaigns'

export function listCampaigns({ includeArchived, perPage, token, projectId } = {}) {
  const params = new URLSearchParams()
  if (includeArchived) params.set('include_archived', 'true')
  if (perPage) params.set('per_page', perPage)
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => CampaignListSchema.parse(data).campaigns)
}

export function getCampaign(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => CampaignSchema.parse(data))
}

export function createCampaign(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CampaignSchema.parse(data))
}

export function updateCampaign(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => CampaignSchema.parse(data))
}

export function exportCampaigns({ includeArchived, token, projectId }) {
  const path = includeArchived ? `${BASE}/export?include_archived=true` : `${BASE}/export`
  return apiDownload(path, { token, projectId, filename: 'campaigns.csv' })
}
