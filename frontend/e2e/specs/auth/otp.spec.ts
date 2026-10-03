import { test, expect } from '@playwright/test'
import { TOTP } from 'otpauth'
import { readFixture } from '../../fixtures/fixtureData'

// Runs against a user dedicated to this spec alone (reset fresh — OTP
// disabled — at the start of every full suite run by backend/lib/tasks/
// e2e.rake), so enabling/disabling OTP here never affects the main fixture
// user whose token the rest of the suite reuses via storageState.
//
// User#verify_otp uses a standard ROTP::TOTP (HMAC-SHA1, 30s step, 6 digits,
// Base32 secret) — exactly what the `otpauth` npm package computes, so a
// real code can be generated here without scanning the QR image.
function codeFor(secret: string): string {
  return new TOTP({ secret, algorithm: 'SHA1', digits: 6, period: 30 }).generate()
}

test('enrolls in two-factor authentication, logs out, and logs back in through the OTP challenge', async ({ page }) => {
  const fixture = readFixture()

  await page.goto('/login')
  await page.locator('#email').fill(fixture.otp_user_email)
  await page.locator('#password input').fill(fixture.otp_user_password)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await expect(page).toHaveURL('/')

  await page.goto('/settings')
  const secret = await page.locator('code.secret').innerText()
  await page.locator('#otp-confirm-code').fill(codeFor(secret))
  await page.getByRole('button', { name: 'Confirm' }).click()

  await expect(page.getByText('Save these backup codes')).toBeVisible()
  await page.getByRole('button', { name: "I've saved these codes" }).click()
  await expect(page.getByText('Two-factor authentication is enabled')).toBeVisible()

  await page.getByRole('button', { name: 'Sign out' }).click()
  await expect(page).toHaveURL('/login')

  await page.locator('#email').fill(fixture.otp_user_email)
  await page.locator('#password input').fill(fixture.otp_user_password)
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page.getByText('Two-factor authentication')).toBeVisible()
  await page.locator('#otp-code').fill(codeFor(secret))
  await page.getByRole('button', { name: 'Verify' }).click()

  await expect(page).toHaveURL('/')
  await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible()

  // Cleanup — leaves the dedicated OTP user's state matching what the rake
  // task resets it to anyway, so a partial suite re-run stays consistent.
  await page.goto('/settings')
  await page.getByRole('button', { name: 'Disable two-factor authentication' }).click()
  await page.locator('#otp-disable-password input').fill(fixture.otp_user_password)
  await page.getByRole('button', { name: 'Disable two-factor authentication' }).click()
  await expect(page.getByText('Two-factor authentication disabled')).toBeVisible()
})
