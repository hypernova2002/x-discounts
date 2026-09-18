import { z } from 'zod'

// Response shape. .passthrough() so a harmless new backend field never breaks
// parsing — this is a drift safety net, not an untrusted-input boundary (the
// backend already validates everything server-side).
export const MembershipTierSchema = z
  .object({
    id: z.string(),
    name: z.string(),
    rank: z.number(),
    grace_period_days: z.number().nullable(),
    requirements_condition: z.record(z.any()),
    auto_assignable: z.boolean(),
    membership_scheme: z.object({ id: z.string(), name: z.string() }).passthrough(),
    created_at: z.string(),
    updated_at: z.string(),
  })
  .passthrough()

// Form input. A factory (not a module-level constant) so validation messages
// are real i18n keys from the caller's own namespace. Matches exactly what the
// current "add tier" mini-form collects — name + rank. The edit-tier dialog also
// collects requirements_condition and grace_period_days, but those aren't
// client-validated here (the backend validates them; the UI didn't validate them
// before this refactor either).
export function membershipTierInputSchema(t) {
  return z.object({
    name: z.string().min(1, t('membershipSchemeDetail.tierNameRequired')),
    rank: z.number({ message: t('membershipSchemeDetail.tierRankRequired') }).int(t('membershipSchemeDetail.tierRankRequired')),
  })
}
