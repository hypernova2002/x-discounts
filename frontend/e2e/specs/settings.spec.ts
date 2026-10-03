import { test, expect } from '@playwright/test'
import { uniqueSuffix } from '../support/unique'
import { textField } from '../support/controls'

test('updates project settings', async ({ page }) => {
  await page.goto('/project-settings')
  const newName = `E2E Fixture ${uniqueSuffix()}`
  await textField(page, 'project-name').fill(newName)
  await page.getByRole('button', { name: 'Save', exact: true }).click()

  await expect(page.getByText('Project updated')).toBeVisible()
})

test('updates the signed-in user\'s profile', async ({ page }) => {
  await page.goto('/settings')
  const newName = `E2E Tester ${uniqueSuffix()}`
  await textField(page, 'settings-name').fill(newName)
  await page.getByRole('button', { name: 'Save' }).first().click()

  await expect(page.getByText('Profile updated')).toBeVisible()
})

test('updates account settings', async ({ page }) => {
  await page.goto('/account')
  const newName = `E2E Test Account ${uniqueSuffix()}`
  await textField(page, 'account-name').fill(newName)
  await page.getByRole('button', { name: 'Save', exact: true }).click()

  await expect(page.getByText('Account updated')).toBeVisible()
})
