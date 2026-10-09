import { apiFetch, type AuthParams } from '@/lib/api'
import { ExportSchema, ExportListSchema, type EXPORT_TYPES } from '@/models/export'

const BASE = '/api/v1/admin/exports'

interface ListExportsParams extends AuthParams {
  perPage?: number
}

export function listExports({ perPage, token, projectId }: ListExportsParams = {}) {
  const path = perPage ? `${BASE}?per_page=${perPage}` : BASE
  return apiFetch(path, { token, projectId }).then((data) => ExportListSchema.parse(data).exports)
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
