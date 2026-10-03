import { apiFetch, type AuthParams } from '@/lib/api'
import { UserSchema, UserListSchema, type UserInput, type AdminResetPasswordInput } from '@/models/user'

const BASE = '/api/v1/admin/users'

export function listUsers({ token, projectId }: AuthParams) {
  return apiFetch(BASE, { token, projectId }).then((data) => UserListSchema.parse(data).users)
}

export function createUser(input: UserInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => UserSchema.parse(data))
}

export function updateUser(id: string, input: Partial<UserInput>, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => UserSchema.parse(data))
}

export function resetUserPassword(id: string, input: AdminResetPasswordInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/reset_password`, { method: 'PATCH', token, projectId, body: input })
}

export function resetUserOtp(id: string, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}/reset_otp`, { method: 'POST', token, projectId }).then((data) => UserSchema.parse(data))
}
