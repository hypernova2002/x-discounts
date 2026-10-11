import { apiFetch, type AuthParams } from '@/lib/api'
import { ExportSchema, ExportListSchema, type EXPORT_TYPES } from '@/models/export'

const BASE = '/api/v1/admin/exports'

interface ListExportsParams extends AuthParams {
  perPage?: number
  includes?: string[]
}

export function listExports({ perPage, includes, token, projectId }: ListExportsParams = {}) {
  const params = new URLSearchParams()
  if (perPage) params.set('per_page', String(perPage))
  if (includes?.length) params.set('includes', includes.join(','))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => ExportListSchema.parse(data).exports)
}

export function getExport(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { token, projectId }).then((data) => ExportSchema.parse(data))
}

export interface CreateExportInput {
  export_type: (typeof EXPORT_TYPES)[number]
  params?: Record<string, unknown>
}

export function createExport(input: CreateExportInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => ExportSchema.parse(data))
}

export function exportDownloadPath(id: string): string {
  return `${BASE}/${id}/download`
}
