import { apiFetch, type AuthParams } from '@/lib/api'
import type { ChangePasswordInput, OtpCodeInput } from '@/models/user'

const BASE = '/api/v1/me'

export function updatePassword(input: ChangePasswordInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/password`, { method: 'PATCH', token, projectId, body: input })
}

interface SetupOtpResponse {
  secret: string
  provisioning_uri: string
}

export function setupOtp({ token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/otp/setup`, { method: 'POST', token, projectId }) as Promise<SetupOtpResponse>
}

interface EnableOtpResponse {
  backup_codes: string[]
}

export function enableOtp(input: OtpCodeInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/otp/enable`, { method: 'POST', token, projectId, body: input }) as Promise<EnableOtpResponse>
}

interface DisableOtpInput {
  current_password: string
}

export function disableOtp(input: DisableOtpInput, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/otp/disable`, { method: 'POST', token, projectId, body: input })
}
