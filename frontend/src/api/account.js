import { apiFetch } from '@/lib/api'
import { AccountSchema } from '@/models/account'

const BASE = '/api/v1/admin/account'

export function getAccount({ token, projectId }) {
  return apiFetch(BASE, { token, projectId }).then((data) => AccountSchema.parse(data))
}

export function updateAccount(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'PATCH', token, projectId, body: input }).then((data) => AccountSchema.parse(data))
}
