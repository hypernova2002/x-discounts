import { z } from 'zod'

export const EXPORT_TYPES = ['campaigns', 'customers', 'orders', 'project'] as const
export const EXPORT_STATUSES = ['pending', 'processing', 'completed', 'failed'] as const

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const ExportSchema = z
  .object({
    id: z.string(),
    export_type: z.enum(EXPORT_TYPES),
    status: z.enum(EXPORT_STATUSES),
    filename: z.string().nullable(),
    byte_size: z.number().nullable(),
    error_message: z.string().nullable(),
    created_at: z.string(),
    completed_at: z.string().nullable(),
    requested_by: z.string().nullable(),
  })
  .passthrough()

export type Export = z.infer<typeof ExportSchema>

export const ExportListSchema = z.object({ exports: z.array(ExportSchema) }).passthrough()

export type ExportList = z.infer<typeof ExportListSchema>
