// The full ISO 4217 active currency code list, straight from the browser —
// same data source the backend's own validation draws from, just a slightly
// smaller subset there (confirmed: Project::CURRENCIES is a superset), so
// nothing offered here can ever be rejected.
export const CURRENCY_OPTIONS = Intl.supportedValuesOf('currency').map((code) => ({
  value: code,
  label: `${code} — ${currencyName(code)}`,
}))

function currencyName(code) {
  try {
    return new Intl.DisplayNames('en', { type: 'currency' }).of(code)
  } catch {
    return code
  }
}
