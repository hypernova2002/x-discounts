const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001'

export class ApiError extends Error {
  constructor(message, status, body, code) {
    super(message)
    this.status = status
    this.body = body
    this.code = code
  }

  // Raw {field, message}[] from the backend's ValidationError, when present —
  // lets a form map server-side field errors onto the same per-field error
  // state a client-side (zod) validation failure would populate.
  get details() {
    return this.body?.error?.details ?? []
  }
}

async function handleResponse(response) {
  const isJson = response.headers.get('content-type')?.includes('application/json')
  const data = isJson ? await response.json() : null

  if (!response.ok) {
    const err = data?.error
    let message = err?.message || `Request failed with status ${response.status}`
    if (err?.details?.length) {
      message += ': ' + err.details.map((d) => (d.field && d.field !== 'base' ? `${d.field} ${d.message}` : d.message)).join(', ')
    }
    throw new ApiError(message, response.status, data, err?.code)
  }

  return data
}

export async function apiFetch(path, { method = 'GET', token, projectId, body } = {}) {
  const headers = { 'Content-Type': 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  if (projectId) headers['X-Project-Id'] = projectId

  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })

  return handleResponse(response)
}

// For multipart file uploads — deliberately doesn't set Content-Type itself, so the
// browser can add the multipart boundary automatically.
export async function apiUpload(path, { token, projectId, fieldName, file }) {
  const headers = {}
  if (token) headers.Authorization = `Bearer ${token}`
  if (projectId) headers['X-Project-Id'] = projectId

  const formData = new FormData()
  formData.append(fieldName, file)

  const response = await fetch(`${BASE_URL}${path}`, { method: 'POST', headers, body: formData })

  return handleResponse(response)
}

export function apiFileUrl(path) {
  return `${BASE_URL}${path}`
}

// For downloads that require auth headers (a plain <a href> can't send them) — fetches
// the file as a blob and triggers a normal browser save via a throwaway <a download>.
export async function apiDownload(path, { token, projectId, filename }) {
  const headers = {}
  if (token) headers.Authorization = `Bearer ${token}`
  if (projectId) headers['X-Project-Id'] = projectId

  const response = await fetch(`${BASE_URL}${path}`, { headers })
  if (!response.ok) {
    await handleResponse(response)
  }

  const blob = await response.blob()
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}
