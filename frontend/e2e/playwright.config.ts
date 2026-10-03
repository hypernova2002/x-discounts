import { defineConfig, devices } from '@playwright/test'
import { fileURLToPath } from 'node:url'
import { authFile } from './support/authFile'

// Targets the already-running `docker compose` dev stack (frontend on
// :5175, backend on :3001) — this suite doesn't manage the stack's
// lifecycle, matching how every manual browser check this session worked.
// `globalSetup` resets the dedicated "E2E Fixture" project before the run.
export default defineConfig({
  testDir: '.',
  fullyParallel: true,
  retries: 1,
  reporter: 'html',
  globalSetup: fileURLToPath(new URL('global-setup.ts', import.meta.url)),
  use: {
    baseURL: 'http://localhost:5175',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'setup', testMatch: /setup\/auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], storageState: authFile },
      dependencies: ['setup'],
      testIgnore: /auth\/(login|otp)\.spec\.ts/,
    },
    {
      // login/otp specs test the real sign-in form from a clean slate — no
      // pre-seeded storageState, and no dependency on the `setup` project
      // (which would race the OTP spec's own user-state resets otherwise).
      name: 'chromium-unauthenticated',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /auth\/(login|otp)\.spec\.ts/,
    },
  ],
})
