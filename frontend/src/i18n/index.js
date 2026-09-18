import { createI18n } from 'vue-i18n'

// Each view/component owns one JSON file per locale under locales/<code>/, keyed by
// its own top-level namespace (e.g. locales/en/customers.json -> {"customers": {...}},
// locales/ja/customers.json -> the same keys, Japanese values). Auto-loaded via glob
// so adding a new namespace file — or a whole new locale directory — is the only
// step needed; nothing here, or anywhere else, has to be told about it.
const modules = import.meta.glob('./locales/*/*.json', { eager: true })
const messages = {}
for (const [path, mod] of Object.entries(modules)) {
  const locale = path.split('/')[2]
  messages[locale] ??= {}
  Object.assign(messages[locale], mod.default ?? mod)
}

export const AVAILABLE_LOCALES = [
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'ja', label: '日本語', flag: '🇯🇵' },
]

export const i18n = createI18n({
  legacy: false,
  globalInjection: true, // $t available in every template without importing useI18n
  locale: 'en',
  fallbackLocale: 'en',
  messages,
})

export function setLocale(locale) {
  if (locale && i18n.global.availableLocales.includes(locale)) {
    i18n.global.locale.value = locale
  }
}
