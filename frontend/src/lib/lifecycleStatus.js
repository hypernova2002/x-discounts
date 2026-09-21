import { formatDateRange } from '@/lib/format'

const DAY_MS = 24 * 60 * 60 * 1000
// "Ends in N days" only shows up this close to the end — past this, the plain
// date range on its own is more useful than a constantly-changing day count.
const ENDS_SOON_THRESHOLD_DAYS = 14

// Derives a campaign/discount's lifecycle from its own enabled/archived flags and
// validity window — shared by Campaign (valid_from/valid_until) and every Discount
// kind (promotion/loyalty: active_from/active_until, coupon: valid_from/valid_until),
// since all of them follow the same enabled -> archived -> date-window shape.
// `t` is the caller's own useI18n() t (this module stays presentation-only, same
// reasoning as formatRelativeDateTime in lib/format.js).
export function deriveLifecycleStatus({ enabled, archived, from, until, timezone, now = new Date(), t }) {
  const start = from ? new Date(from) : null
  const end = until ? new Date(until) : null

  let state
  if (archived) state = 'archived'
  else if (!enabled) state = 'paused'
  else if (start && start > now) state = 'pending'
  else if (end && end < now) state = 'expired'
  else state = 'active'

  let contextLine = formatDateRange(from, until, timezone)
  if (state === 'pending' && start) contextLine = t('lifecycleStatus.starts', { date: formatDateRange(from, null, timezone) })
  else if (state === 'expired' && end) contextLine = t('lifecycleStatus.ended', { date: formatDateRange(null, until, timezone) })

  let endsInDays = null
  if (state === 'active' && end) {
    const days = Math.ceil((end - now) / DAY_MS)
    if (days >= 0 && days <= ENDS_SOON_THRESHOLD_DAYS) endsInDays = days
  }

  return { state, contextLine, endsInDays }
}
