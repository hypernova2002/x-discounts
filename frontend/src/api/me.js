import { apiFetch } from '@/lib/api'

const BASE = '/api/v1/me'

export function updatePassword(input, { token, projectId }) {
  return apiFetch(`${BASE}/password`, { method: 'PATCH', token, projectId, body: input })
}

export function setupOtp({ token, projectId }) {
  return apiFetch(`${BASE}/otp/setup`, { method: 'POST', token, projectId })
}

export function enableOtp(input, { token, projectId }) {
  return apiFetch(`${BASE}/otp/enable`, { method: 'POST', token, projectId, body: input })
}

export function disableOtp(input, { token, projectId }) {
  return apiFetch(`${BASE}/otp/disable`, { method: 'POST', token, projectId, body: input })
}
