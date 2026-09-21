import { i18n } from '@/i18n'

function currentLocale() {
  return i18n.global.locale.value
}

const REGIONAL_INDICATOR_OFFSET = 127397

// A regional-indicator flag emoji from a 2-letter ISO-3166-1 alpha-2 code
// ("US" -> 🇺🇸), the standard technique (each letter maps to its own Unicode
// "regional indicator symbol" codepoint, and terminals/fonts render an
// adjacent pair as one flag glyph). This app has never validated Customer#country's
// format — confirmed live against real data that every value in this app is
// already a clean 2-letter code, but returns null for anything else so a
// stray free-text value never renders as a broken/wrong flag.
export function countryFlag(code) {
  if (!code || !/^[a-zA-Z]{2}$/.test(code)) return null
  return String.fromCodePoint(...code.toUpperCase().split('').map((c) => REGIONAL_INDICATOR_OFFSET + c.charCodeAt(0)))
}

// Full country name via the browser's own locale data — falls back to the
// raw code if it can't resolve one (an unrecognized/non-conforming value).
export function countryName(code) {
  if (!code) return ''
  try {
    const displayNames = new Intl.DisplayNames([currentLocale()], { type: 'region' })
    return displayNames.of(code.toUpperCase()) || code
  } catch {
    return code
  }
}
