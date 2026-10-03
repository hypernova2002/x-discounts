let counter = 0

// A short, collision-safe suffix for naming records a test creates — unique
// across parallel workers/files without needing any cross-test coordination.
export function uniqueSuffix(): string {
  counter += 1
  return `${Date.now()}-${process.pid}-${counter}`
}
