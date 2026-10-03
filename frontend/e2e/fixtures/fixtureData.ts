import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import type { E2eFixture } from '../global-setup'

const FIXTURE_PATH = fileURLToPath(new URL('../.fixture.json', import.meta.url))

let cached: E2eFixture | null = null

// Reads the fixture global-setup wrote (project id, API key, both test users'
// credentials). Cached per worker process — the file never changes mid-run.
export function readFixture(): E2eFixture {
  if (!cached) {
    cached = JSON.parse(readFileSync(FIXTURE_PATH, 'utf-8')) as E2eFixture
  }
  return cached
}
