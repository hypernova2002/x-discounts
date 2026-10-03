import { z } from 'zod'
import type { ComposerTranslation } from 'vue-i18n'
import { MembershipTierSchema } from '@/models/membershipTier'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const MembershipSchemeSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    created_at: z.string(),
    updated_at: z.string(),
    tiers: z.array(MembershipTierSchema),
  })
  .passthrough()

export type MembershipScheme = z.infer<typeof MembershipSchemeSchema>

export const MembershipSchemeListSchema = z.object({ membership_schemes: z.array(MembershipSchemeSchema) }).passthrough()

export type MembershipSchemeList = z.infer<typeof MembershipSchemeListSchema>

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (membershipSchemeForm.json).
// Shared by create and update — update applies .partial() at the call site.
export function membershipSchemeInputSchema(t: ComposerTranslation) {
  return z.object({
    name: z.string().min(1, t('membershipSchemeForm.nameRequired')),
  })
}

export type MembershipSchemeInput = z.infer<ReturnType<typeof membershipSchemeInputSchema>>
