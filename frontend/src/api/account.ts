import { apiFetch, type AuthParams } from '@/lib/api'
import { AccountSchema, type AccountInput } from '@/models/account'

const BASE = '/api/v1/admin/account'

export function getAccount({ token, projectId }: AuthParams) {
  return apiFetch(BASE, { token, projectId }).then((data) => AccountSchema.parse(data))
}

export function updateAccount(input: AccountInput & { otp_required?: boolean }, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'PATCH', token, projectId, body: input }).then((data) => AccountSchema.parse(data))
}
