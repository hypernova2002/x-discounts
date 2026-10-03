import { test, expect } from '@playwright/test'
import { readFixture } from '../../fixtures/fixtureData'

// Runs with no stored auth (see playwright.config.ts's chromium-unauthenticated
// project) — the only spec that drives the real login form rather than
// seeding localStorage directly. The E2E fixture user belongs to exactly one
// project, so a successful login lands straight on the dashboard with no
// select-project step in between.

test('redirects an unauthenticated visit to a protected route to /login, preserving the destination', async ({ page }) => {
  await page.goto('/campaigns')
  await expect(page).toHaveURL(/\/login\?redirect=\/campaigns/)
})

test('rejects invalid credentials with an inline error, no navigation', async ({ page }) => {
  await page.goto('/login')
  await page.locator('#email').fill('not-a-real-user@x-discounts.test')
  await page.locator('#password input').fill('wrong-password')
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page.getByText(/incorrect/i)).toBeVisible()
  await expect(page).toHaveURL('/login')
})

test('logs in with valid credentials and signs out', async ({ page }) => {
  const fixture = readFixture()

  await page.goto('/login')
  await page.locator('#email').fill(fixture.user_email)
  await page.locator('#password input').fill(fixture.user_password)
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible()

  await page.getByRole('button', { name: 'Sign out' }).click()
  await expect(page).toHaveURL('/login')
})
