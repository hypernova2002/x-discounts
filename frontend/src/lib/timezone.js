import { DateTime } from 'luxon'

function offsetLabel(zone) {
  const part = new Intl.DateTimeFormat('en', { timeZone: zone, timeZoneName: 'shortOffset' })
    .formatToParts(new Date())
    .find((p) => p.type === 'timeZoneName')
  return part?.value ?? zone
}

// The full canonical IANA identifier list, straight from the browser — same
// data source the backend's own validation draws from (TZInfo), just a
// slightly larger superset there, so nothing offered here can ever be
// rejected. No polyfill needed for this app's audience (internal admin tool).
//
// `Intl.supportedValuesOf('timeZone')` excludes "UTC" itself (confirmed —
// it returns no UTC/GMT/Etc/Universal/Zulu entry at all), even though "UTC"
// is a perfectly valid `timeZone` value everywhere else (Intl.DateTimeFormat,
// Luxon) — it's just missing from this one enumeration. Every project
// defaults to exactly "UTC" (the DB column is NOT NULL DEFAULT 'UTC'), so
// without prepending it here, that default value has no matching option and
// the picker renders as unset even though the underlying value is real.
export const TIMEZONE_OPTIONS = [
  { value: 'UTC', label: `UTC (${offsetLabel('UTC')})` },
  ...Intl.supportedValuesOf('timeZone').map((zone) => ({
    value: zone,
    label: `${zone} (${offsetLabel(zone)})`,
  })),
]

const DATETIME_LOCAL_FORMAT = "yyyy-MM-dd'T'HH:mm"

// UTC ISO string -> the wall-clock string a `datetime-local` input expects,
// as it reads in the given IANA zone. Inverse of `zonedInputToIso`.
export function isoToZonedInput(iso, zone) {
  if (!iso) return ''
  const dt = DateTime.fromISO(iso, { zone: 'utc' }).setZone(zone)
  return dt.isValid ? dt.toFormat(DATETIME_LOCAL_FORMAT) : ''
}

// A `datetime-local` input's wall-clock string, interpreted as being in the
// given IANA zone -> the correct UTC ISO string for the API. Inverse of
// `isoToZonedInput`.
export function zonedInputToIso(local, zone) {
  if (!local) return null
  const dt = DateTime.fromFormat(local, DATETIME_LOCAL_FORMAT, { zone })
  return dt.isValid ? dt.toUTC().toISO() : null
}
