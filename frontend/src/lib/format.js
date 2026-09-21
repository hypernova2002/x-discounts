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
    timeZone: timezone,
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

// ISO-style date + 24h time: "2026-09-17 13:14".
export function formatDateTime(value, timezone) {
  if (!value) return ''
  const p = dateParts(value, timezone)
  if (!p) return ''
  return `${p.year}-${p.month}-${p.day} ${p.hour}:${p.minute}`
}
