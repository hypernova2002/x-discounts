import { i18n } from '@/i18n'

function currentLocale() {
  return i18n.global.locale.value
}

// Integer when the value is whole, otherwise up to 2 decimals — with the
// locale's thousands separator (e.g. 1234 -> "1,234", 19.5 -> "19.5").
export function formatNumber(value) {
  if (value === null || value === undefined || value === '') return ''
  const num = Number(value)
  if (Number.isNaN(num)) return String(value)
  return new Intl.NumberFormat(currentLocale(), { maximumFractionDigits: 2 }).format(num)
}

// "1.2K" / "12.4K" / "1.2M" — for large summary metrics only (spec: prefer full
// values via formatNumber in tables, abbreviated only where appropriate).
export function formatAbbreviatedNumber(value) {
  if (value === null || value === undefined || value === '') return ''
  const num = Number(value)
  if (Number.isNaN(num)) return String(value)
  return new Intl.NumberFormat(currentLocale(), { notation: 'compact', maximumFractionDigits: 1 }).format(num)
}

// Extracts Y/M/D/h/m as seen in `timezone` (an IANA identifier, e.g. the
// current project's) — or, when `timezone` is omitted, in the browser's own
// local zone (Intl.DateTimeFormat's default when `timeZone` isn't passed),
// which is the pre-existing/legacy behavior every call site had before any
// caller threaded a project timezone through. `hourCycle: 'h23'` (not
// `hour12: false`) specifically to avoid a well-known Intl quirk where
// midnight formats as hour "24" instead of "00" in some engines.
function dateParts(value, timezone) {
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return null
  const parts = new Intl.DateTimeFormat(currentLocale(), {
    // `timeZone: null` throws (RangeError) where `timeZone: undefined` is
    // silently treated as "not specified" and falls back to the system
    // zone — coerce so an unloaded/absent project timezone degrades
    // gracefully instead of crashing the caller's render.
    timeZone: timezone || undefined,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(d)
  const get = (type) => parts.find((p) => p.type === type)?.value
  return { year: get('year'), month: get('month'), day: get('day'), hour: get('hour'), minute: get('minute') }
}

// ISO-style date: "2026-09-17".
export function formatDate(value, timezone) {
  if (!value) return ''
  const p = dateParts(value, timezone)
  if (!p) return ''
  return `${p.year}-${p.month}-${p.day}`
}

// "Sep 1" — for a plain "YYYY-MM-DD" calendar-day bucket (e.g. an analytics
// series point), never a timezone-aware instant. Deliberately takes no
// timezone: the string is already the day a backend day-grouped query bucketed
// into, so reinterpreting it through a project timezone (like formatDate does
// for a real timestamp) could shift it a day either way — this always reads
// the Y/M/D digits as given and formats them in UTC, which is a no-op shift.
export function formatCalendarDate(isoDate) {
  if (!isoDate) return ''
  const [year, month, day] = isoDate.split('-').map(Number)
  const d = new Date(Date.UTC(year, month - 1, day))
  return new Intl.DateTimeFormat(currentLocale(), { timeZone: 'UTC', month: 'short', day: 'numeric' }).format(d)
}

// ISO-style date + 24h time: "2026-09-17 13:14".
export function formatDateTime(value, timezone) {
  if (!value) return ''
  const p = dateParts(value, timezone)
  if (!p) return ''
  return `${p.year}-${p.month}-${p.day} ${p.hour}:${p.minute}`
}

// This app has no currency concept anywhere in the data model (projects/accounts
// have no currency field, same gap as the earlier finding that there's no payment
// concept at all) — USD is a fixed assumption, matching the design spec's own
// examples, not a per-project setting.
export function formatCurrency(value) {
  if (value === null || value === undefined || value === '') return ''
  const num = Number(value)
  if (Number.isNaN(num)) return String(value)
  return new Intl.NumberFormat(currentLocale(), { style: 'currency', currency: 'USD' }).format(num)
}

// Takes a plain percentage number (18.4, not 0.184) -> "18.4%".
export function formatPercent(value) {
  if (value === null || value === undefined || value === '') return ''
  const num = Number(value)
  if (Number.isNaN(num)) return String(value)
  return `${new Intl.NumberFormat(currentLocale(), { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(num)}%`
}

function monthDayYearParts(value, timezone) {
  const d = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(d.getTime())) return null
  // See dateParts' comment: `null` throws, `undefined` degrades gracefully.
  const parts = new Intl.DateTimeFormat(currentLocale(), { timeZone: timezone || undefined, year: 'numeric', month: 'short', day: 'numeric' }).formatToParts(d)
  const get = (type) => parts.find((p) => p.type === type)?.value
  return { year: get('year'), month: get('month'), day: get('day') }
}

function formatSingle(p) {
  return `${p.month} ${p.day}, ${p.year}`
}

// "MMM D, YYYY" for a single date — e.g. "Sep 17, 2026".
export function formatMonthDayYear(value, timezone) {
  if (!value) return ''
  const p = monthDayYearParts(value, timezone)
  if (!p) return ''
  return formatSingle(p)
}

// "MMM D, YYYY" ranges, per this app's date-range convention:
//  - one side missing -> just the other side's single date (callers add their own
//    "Starts"/"Ended" wording, e.g. lifecycleStatus.js, since that's contextual to
//    what's being described, not to date formatting itself).
//  - same month -> "Sep 1–30, 2026"
//  - different month, same year -> "Sep 28 – Oct 5, 2026"
//  - different year -> "Dec 28, 2026 – Jan 5, 2027"
//  - same day (or only one side given) -> "Sep 1, 2026"
export function formatDateRange(from, until, timezone) {
  const start = from ? monthDayYearParts(from, timezone) : null
  const end = until ? monthDayYearParts(until, timezone) : null
  if (!start && !end) return ''
  if (start && !end) return formatSingle(start)
  if (!start && end) return formatSingle(end)

  if (start.year !== end.year) return `${formatSingle(start)} – ${formatSingle(end)}`
  if (start.month !== end.month) return `${start.month} ${start.day} – ${end.month} ${end.day}, ${end.year}`
  if (start.day !== end.day) return `${start.month} ${start.day}–${end.day}, ${end.year}`
  return formatSingle(start)
}

function zonedDateKey(date, timezone) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: timezone || undefined, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date)
}

const DAY_MS = 24 * 60 * 60 * 1000

// { short, full } for a timestamp, relative to "now" in `timezone`:
//  - today -> t('format.todayAt', { time })       e.g. "Today, 3:42 PM"
//  - yesterday -> t('format.yesterdayAt', { time }) e.g. "Yesterday, 11:18 AM"
//  - older -> "Sep 14, 2026"
// `full` is always the complete absolute timestamp (for a tooltip), e.g.
// "September 21, 2026 at 3:42:18 PM JST". `t` is the caller's own useI18n() t —
// this file stays presentation-only, it doesn't own translated wording itself.
export function formatRelativeDateTime(value, timezone, t) {
  if (!value) return { short: '', full: '' }
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return { short: '', full: '' }

  const locale = currentLocale()
  const now = new Date()
  const todayKey = zonedDateKey(now, timezone)
  const valueKey = zonedDateKey(d, timezone)
  const yesterdayKey = zonedDateKey(new Date(now.getTime() - DAY_MS), timezone)

  const time = new Intl.DateTimeFormat(locale, { timeZone: timezone || undefined, hour: 'numeric', minute: '2-digit', hour12: true }).format(d)

  let short
  if (valueKey === todayKey) short = t('format.todayAt', { time })
  else if (valueKey === yesterdayKey) short = t('format.yesterdayAt', { time })
  else short = formatSingle(monthDayYearParts(d, timezone))

  const longDate = new Intl.DateTimeFormat(locale, { timeZone: timezone || undefined, year: 'numeric', month: 'long', day: 'numeric' }).format(d)
  const fullTime = new Intl.DateTimeFormat(locale, {
    timeZone: timezone || undefined,
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
    hour12: true,
    timeZoneName: 'short',
  }).format(d)

  return { short, full: t('format.fullTimestamp', { date: longDate, time: fullTime }) }
}
