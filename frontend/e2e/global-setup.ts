import { execSync } from 'node:child_process'
import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

export interface E2eFixture {
  project_id: string
  api_key: string
  user_email: string
  user_password: string
  otp_user_email: string
  otp_user_password: string
}

const FIXTURE_PATH = fileURLToPath(new URL('.fixture.json', import.meta.url))
const SENTINEL = 'E2E_FIXTURE_JSON='

// Resets the dedicated "E2E Fixture" project to a clean, known state (see
// backend/lib/tasks/e2e.rake) and writes what the suite needs to authenticate
// and talk to the real API into e2e/.fixture.json. Runs via `docker compose
// exec` against the already-running dev stack (started separately — this
// suite deliberately doesn't manage the stack's lifecycle, matching how every
// manual smoke pass this session worked against the already-published
// localhost ports).
export default function globalSetup() {
  const repoRoot = fileURLToPath(new URL('../..', import.meta.url))

  let output: string
  try {
    output = execSync('docker compose exec -T app bundle exec rake e2e:reset', {
      cwd: repoRoot,
      encoding: 'utf-8',
    })
  } catch (error) {
    throw new Error(
      `Failed to reset the E2E fixture project via "docker compose exec app bundle exec rake e2e:reset". ` +
        `Make sure the dev stack is running (docker compose up -d) before running the E2E suite.`,
      { cause: error },
    )
  }

  const line = output.split('\n').find((l) => l.startsWith(SENTINEL))
  if (!line) {
    throw new Error(`Could not find "${SENTINEL}" line in rake task output:\n${output}`)
  }

  const fixture: E2eFixture = JSON.parse(line.slice(SENTINEL.length))
  writeFileSync(FIXTURE_PATH, JSON.stringify(fixture, null, 2))
}
