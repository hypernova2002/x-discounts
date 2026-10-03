import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { test, expect, createGiftShopItem, createCustomer, grantPoints } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'
import { textField, innerInput } from '../support/controls'

test('create requires a name and points cost, then succeeds with a photo', async ({ page }) => {
  await page.goto('/gift-shop')
  await page.getByRole('button', { name: 'New item' }).click()
  await expect(page).toHaveURL('/gift-shop/new')

  await page.getByRole('button', { name: 'Create item' }).click()
  await expect(page.getByText('Name is required')).toBeVisible()

  const name = `E2E Gift Item ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await innerInput(page, 'points_cost').fill('150')
  await page.locator('#photo').setInputFiles(fileURLToPath(new URL('../fixtures/test-image.png', import.meta.url)))
  await page.getByRole('button', { name: 'Create item' }).click()

  await expect(page).toHaveURL('/gift-shop')
  await expect(page.getByText(name)).toBeVisible()
})

test('redeems an item for a customer with enough points', async ({ page, apiContext }) => {
  const item = await createGiftShopItem(apiContext, { points_cost: 50 })
  const customer = await createCustomer(apiContext)
  await grantPoints(apiContext, customer.id, 100)

  await page.goto('/gift-shop')
  const card = page.locator('.item-card').filter({ hasText: item.name })
  await card.getByRole('button', { name: 'Redeem', exact: true }).click()

  await page.getByRole('dialog').getByRole('textbox').fill(customer.external_id)
  await page.getByRole('dialog').getByRole('spinbutton').fill('1')
  await page.getByRole('dialog').getByRole('button', { name: 'Redeem', exact: true }).click()

  await expect(page.getByText('Redeemed')).toBeVisible()
})
