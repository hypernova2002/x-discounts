import { test, expect, createMembershipScheme } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'
import { textField } from '../support/controls'

test('list shows an empty state for a search that matches nothing', async ({ page }) => {
  await page.goto('/membership-schemes')
  await page.getByPlaceholder('Search membership schemes').fill(`no-such-scheme-${uniqueSuffix()}`)
  await expect(page.getByText('No results found')).toBeVisible()
})

test('create requires a name, then succeeds', async ({ page }) => {
  await page.goto('/membership-schemes')
  await page.getByRole('button', { name: 'New scheme' }).click()
  await expect(page).toHaveURL('/membership-schemes/new')

  await page.getByRole('button', { name: 'Create scheme' }).click()
  await expect(page.getByText('Name is required')).toBeVisible()

  const name = `E2E Membership ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await page.getByRole('button', { name: 'Create scheme' }).click()

  await expect(page).toHaveURL(/\/membership-schemes\/mscheme_/)
  await expect(page.getByRole('heading', { name })).toBeVisible()
})

test('detail view adds a tier', async ({ page, apiContext }) => {
  const scheme = await createMembershipScheme(apiContext)

  await page.goto(`/membership-schemes/${scheme.id}`)
  await expect(page.getByRole('heading', { name: scheme.name })).toBeVisible()
  await expect(page.getByText('No tiers yet')).toBeVisible()

  await page.getByPlaceholder('Tier name').fill('Gold')
  await page.getByPlaceholder('Rank').fill('1')
  await page.getByRole('button', { name: 'Add tier' }).click()

  await expect(page.getByText('Tier added')).toBeVisible()
  await expect(page.getByRole('cell', { name: 'Gold' })).toBeVisible()
})
