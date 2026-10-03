import { z } from 'zod'
import type { ComposerTranslation } from 'vue-i18n'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const ProjectSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    timezone: z.string(),
    currency: z.string(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export type Project = z.infer<typeof ProjectSchema>

export const ProjectListSchema = z.object({ projects: z.array(ProjectSchema) }).passthrough()

export type ProjectList = z.infer<typeof ProjectListSchema>

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (projects.json).
export function projectInputSchema(t: ComposerTranslation) {
  return z.object({
    name: z.string().min(1, t('projects.nameRequired')),
    timezone: z.string().optional(),
    currency: z.string().optional(),
  })
}

export type ProjectInput = z.infer<ReturnType<typeof projectInputSchema>>
