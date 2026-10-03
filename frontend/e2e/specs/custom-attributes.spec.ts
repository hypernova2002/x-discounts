import { test, expect, createCustomAttribute } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'
import { textField, selectOption } from '../support/controls'

test('creates a custom attribute and shows it in the table', async ({ page }) => {
  await page.goto('/custom-attributes')
  await page.getByRole('button', { name: 'New attribute' }).click()

  const key = `e2e_attr_${uniqueSuffix().replace(/-/g, '_')}`
  await selectOption(page, 'attr-entity', 'Customer')
  await textField(page, 'attr-key').fill(key)
  await selectOption(page, 'attr-type', 'Number')
  await page.getByRole('dialog').getByRole('button', { name: 'Create', exact: true }).click()

  await expect(page.getByText(key)).toBeVisible()
})

test('deletes a custom attribute', async ({ page, apiContext }) => {
  const attribute = await createCustomAttribute(apiContext)

  await page.goto('/custom-attributes')
  await expect(page.getByText(attribute.key)).toBeVisible()

  page.once('dialog', (dialog) => dialog.accept())
  await page.locator('tr', { hasText: attribute.key }).getByRole('button', { name: 'Delete' }).click()

  await expect(page.getByText('Custom attribute deleted')).toBeVisible()
  await expect(page.getByText(attribute.key)).not.toBeVisible()
})
