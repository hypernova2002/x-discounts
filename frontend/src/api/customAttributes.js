import { apiFetch } from '@/lib/api'
import { CustomAttributeSchema, CustomAttributeListSchema } from '@/models/customAttribute'

const BASE = '/api/v1/admin/custom_attributes'

export function listCustomAttributes({ entity, q, token, projectId }) {
  const params = new URLSearchParams()
  if (entity) params.set('entity', entity)
  if (q) params.set('q', q)
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then(
    (data) => CustomAttributeListSchema.parse(data).custom_attributes
  )
}

export function createCustomAttribute(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => CustomAttributeSchema.parse(data))
}

export function deleteCustomAttribute(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'DELETE', token, projectId })
}
