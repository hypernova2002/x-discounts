import { apiFetch } from '@/lib/api'
import { UserSchema, UserListSchema } from '@/models/user'

const BASE = '/api/v1/admin/users'

export function listUsers({ token, projectId }) {
  return apiFetch(BASE, { token, projectId }).then((data) => UserListSchema.parse(data).users)
}

export function createUser(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => UserSchema.parse(data))
}

export function updateUser(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => UserSchema.parse(data))
}

export function resetUserPassword(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}/reset_password`, { method: 'PATCH', token, projectId, body: input })
}

export function resetUserOtp(id, { token, projectId }) {
  return apiFetch(`${BASE}/${id}/reset_otp`, { method: 'POST', token, projectId }).then((data) => UserSchema.parse(data))
}
