import { z } from 'zod'

export const ACTIVITY_LOG_ACTIONS = ['create', 'update', 'delete']

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const ActivityLogSchema = z
  .object({
    id: z.string(),
    action: z.enum(ACTIVITY_LOG_ACTIONS),
    entity_type: z.string(),
    entity_label: z.string(),
    entity_public_id: z.string().nullable(),
    actor_label: z.string().nullable(),
    changes: z.record(z.string(), z.any()),
    request_id: z.string().nullable(),
    created_at: z.string(),
  })
  .passthrough()

export const ActivityLogListSchema = z.object({ activity_logs: z.array(ActivityLogSchema) }).passthrough()
