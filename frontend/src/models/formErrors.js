// Normalizes either a zod validation failure or a caught ApiError (from lib/api.js)
// into the same { [field]: message } shape, so a form's error state can be fed by
// either source through one function. Non-field errors land under '_root'.
export function toFieldErrors(source) {
  const errors = {}

  if (source?.issues) {
    // ZodError (or a safeParse() result's `.error`)
    for (const issue of source.issues) {
      const field = issue.path.length ? issue.path.join('.') : '_root'
      errors[field] = issue.message
    }
    return errors
  }

  if (source?.details?.length) {
    // ApiError with structured field errors
    for (const { field, message } of source.details) {
      errors[field && field !== 'base' ? field : '_root'] = message
    }
    return errors
  }

  if (source?.message) {
    errors._root = source.message
  }

  return errors
}
