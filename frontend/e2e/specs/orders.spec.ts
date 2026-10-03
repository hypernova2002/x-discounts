import { test, expect, createOrder } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'

test('list shows an empty state for a search that matches nothing', async ({ page }) => {
  await page.goto('/orders')
  await page.getByPlaceholder('Search orders').fill(`no-such-order-${uniqueSuffix()}`)
  await expect(page.getByText('No results found')).toBeVisible()
})

test('creates an order with a line item and a customer, then shows its detail page', async ({ page }) => {
  await page.goto('/orders')
  await page.getByRole('button', { name: 'New order' }).click()
  await expect(page).toHaveURL('/orders/new')

  await page.getByPlaceholder('sku').fill(`E2E-SKU-${uniqueSuffix()}`)
  await page.getByPlaceholder('quantity').fill('2')
  await page.getByPlaceholder('unit price').fill('25.00')

  const externalId = `e2e-order-customer-${uniqueSuffix()}`
  await page.locator('.form-section').filter({ hasText: 'Customer' }).getByRole('textbox').first().fill(externalId)

  // Create order stays disabled until a preview has been run against the
  // current cart (see :disabled="... || previewStale" in OrderFormView.vue).
  await page.getByRole('button', { name: 'Preview discounts' }).click()
  await page.getByRole('button', { name: 'Create order' }).click()

  await expect(page).toHaveURL(/\/orders\/ord_/)
  await expect(page.getByRole('heading', { name: /^Order ord_/ })).toBeVisible()
})

test('detail view renders an order created via the API', async ({ page, apiContext }) => {
  const order = await createOrder(apiContext, [{ sku: `E2E-SKU-${uniqueSuffix()}`, quantity: 1, unit_price: 10 }])

  await page.goto(`/orders/${order.id}`)
  await expect(page.getByRole('heading', { name: `Order ${order.id}` })).toBeVisible()
})
