import { apiFetch, type AuthParams } from '@/lib/api'
import { CustomAttributeSchema, CustomAttributeListSchema, type CustomAttributeInput, type CustomAttribute } from '@/models/customAttribute'
import type { PaginatedResult } from '@/models/pagination'

const BASE = '/api/v1/admin/custom_attributes'

interface ListCustomAttributesParams extends AuthParams {
  entity?: string
  q?: string
  page?: number
  perPage?: number
}

export function listCustomAttributes({ entity, q, page, perPage, token, projectId }: ListCustomAttributesParams): Promise<PaginatedResult<CustomAttribute>> {
  const params = new URLSearchParams()
  if (entity) params.set('entity', entity)
  if (q) params.set('q', q)
  if (page) params.set('page', String(page))
  if (perPage) params.set('per_page', String(perPage))
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then((data) => {
    const parsed = CustomAttributeListSchema.parse(data)
    return { items: parsed.custom_attributes, meta: parsed.meta }
  })
}

export function createCustomAttribute(input: CustomAttributeInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CustomAttributeSchema.parse(data))
}

export function deleteCustomAttribute(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'DELETE', token, projectId })
}
