import { z } from 'zod'
import type { ComposerTranslation } from 'vue-i18n'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const AccountSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    otp_required: z.boolean(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export type Account = z.infer<typeof AccountSchema>

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (account.json).
export function accountInputSchema(t: ComposerTranslation) {
  return z.object({
    name: z.string().min(1, t('account.nameRequired')),
  })
}

export type AccountInput = z.infer<ReturnType<typeof accountInputSchema>>
