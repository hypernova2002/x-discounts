import { z } from 'zod'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const UserSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    email: z.string(),
    locale: z.string(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

export const UserListSchema = z.object({ users: z.array(UserSchema) }).passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace (users.json).
export function userInputSchema(t) {
  return z.object({
    name: z.string().min(1, t('users.nameRequired')),
    email: z.string().min(1, t('users.emailRequired')),
  })
}
