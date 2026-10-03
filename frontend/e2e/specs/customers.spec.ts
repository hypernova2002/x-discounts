import { test, expect, createCustomer } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'
import { textField } from '../support/controls'

test('list shows an empty state for a search that matches nothing', async ({ page }) => {
  await page.goto('/customers')
  await page.getByPlaceholder('Search customers').fill(`no-such-customer-${uniqueSuffix()}`)
  await expect(page.getByText('No results found')).toBeVisible()
})

test('list shows a created customer and search finds it', async ({ page, apiContext }) => {
  const customer = await createCustomer(apiContext)

  await page.goto('/customers')
  await page.getByPlaceholder('Search customers').fill(customer.external_id)
  await expect(page.getByText(customer.external_id)).toBeVisible()
})

test('create requires a customer id, then succeeds', async ({ page }) => {
  await page.goto('/customers')
  await page.getByRole('button', { name: 'New customer' }).click()
  await expect(page).toHaveURL('/customers/new')

  await page.getByRole('button', { name: 'Create customer' }).click()
  await expect(page.getByText('Customer ID is required')).toBeVisible()

  const externalId = `e2e-customer-${uniqueSuffix()}`
  await textField(page, 'external_id').fill(externalId)
  await textField(page, 'name').fill('E2E Test Customer')
  await textField(page, 'email').fill('e2e-customer@example.com')
  await page.getByRole('button', { name: 'Create customer' }).click()

  await expect(page).toHaveURL(/\/customers\/cust_/)
  await expect(page.getByText(externalId)).toBeVisible()
  await expect(page.getByRole('heading', { name: 'E2E Test Customer' })).toBeVisible()
})

test('detail view renders the customer and grants loyalty points', async ({ page, apiContext }) => {
  const customer = await createCustomer(apiContext, { name: 'E2E Grant Target' })

  await page.goto(`/customers/${customer.id}`)
  await expect(page.getByText(customer.external_id)).toBeVisible()

  await page.getByRole('button', { name: 'Grant points' }).click()
  await page.getByRole('dialog').getByRole('spinbutton').fill('50')
  await page.getByRole('dialog').getByRole('button', { name: 'Grant' }).click()

  await expect(page.getByText('Points granted')).toBeVisible()
})
