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

function pad(n) {
  return String(n).padStart(2, '0')
}

// ISO-style date, in local time (not UTC, unlike Date#toISOString) so it
// matches what toLocaleString() was showing before — just shorter and
// unambiguous: "2026-09-17".
export function formatDate(value) {
  if (!value) return ''
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return ''
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

// ISO-style date + 24h time, local time: "2026-09-17 13:14".
export function formatDateTime(value) {
  if (!value) return ''
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return ''
  return `${formatDate(value)} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}
