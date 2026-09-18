import { z } from 'zod'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const CampaignSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    enabled: z.boolean(),
    archived: z.boolean(),
    active: z.boolean(),
    valid_from: z.string().nullable(),
    valid_until: z.string().nullable(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export const CampaignListSchema = z.object({ campaigns: z.array(CampaignSchema) }).passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (campaignForm.json).
// Shared by create and update — update applies .partial() at the call site.
export function campaignInputSchema(t) {
  return z.object({
    name: z.string().min(1, t('campaignForm.nameRequired')),
    enabled: z.boolean(),
    valid_from: z.string().nullable(),
    valid_until: z.string().nullable(),
  })
}
