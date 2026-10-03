import { test as setup, expect } from '@playwright/test'
import { readFixture } from '../fixtures/fixtureData'
import { authFile } from '../support/authFile'

const TOKEN_KEY = 'x-discounts.session-token'
const PROJECT_KEY = 'x-discounts.project-id'

// Seeds localStorage with the E2E fixture's API key (confirmed elsewhere this
// session to work interchangeably with a real session token — same Bearer +
// X-Project-Id auth) rather than driving the real login form on every test.
// The login/OTP specs deliberately opt out of this storageState to exercise
// the actual form once.
setup('authenticate', async ({ page }) => {
  const fixture = readFixture()

  await page.goto('/login')
  await page.evaluate(
    ({ tokenKey, token, projectKey, projectId }) => {
      localStorage.setItem(tokenKey, token)
      localStorage.setItem(projectKey, projectId)
    },
    { tokenKey: TOKEN_KEY, token: fixture.api_key, projectKey: PROJECT_KEY, projectId: fixture.project_id },
  )

  await page.goto('/')
  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible()

  await page.context().storageState({ path: authFile })
})
