import { apiFetch } from '@/lib/api'
import { ActivityLogListSchema } from '@/models/activityLog'

const BASE = '/api/v1/admin/activity_logs'

export function listActivityLogs({ entityType, action, userId, from, to, perPage, token, projectId } = {}) {
  const params = new URLSearchParams()
  if (entityType) params.set('entity_type', entityType)
  // `log_action`, not `action` — `action` collides with Rails' own reserved
  // routing param (see backend/app/controllers/api/v1/admin/activity_logs_controller.rb).
  if (action) params.set('log_action', action)
  if (userId) params.set('user_id', userId)
  if (from) params.set('from', from)
  if (to) params.set('to', to)
  if (perPage) params.set('per_page', perPage)
  const query = params.toString()
  return apiFetch(`${BASE}${query ? `?${query}` : ''}`, { token, projectId }).then(
    (data) => ActivityLogListSchema.parse(data).activity_logs
  )
}
