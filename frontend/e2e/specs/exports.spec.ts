import { test, expect, createCampaign, createExport, waitForExportCompletion } from '../fixtures/api'

test('triggering an export from Campaigns auto-downloads once the background job finishes', async ({ page, apiContext }) => {
  await createCampaign(apiContext)

  await page.goto('/campaigns')
  const downloadPromise = page.waitForEvent('download')
  await page.getByRole('button', { name: 'Export campaigns' }).click()
  const download = await downloadPromise

  expect(download.suggestedFilename()).toMatch(/\.csv$/)
})

test('lists recent exports, independent of what any other spec just triggered', async ({ page, apiContext }) => {
  const created = await createExport(apiContext, 'customers')
  const completed = await waitForExportCompletion(apiContext, created.id)
  expect(completed.status).toBe('completed')

  await page.goto('/exports')
  const row = page.locator('tr', { hasText: 'Customers' }).first()
  await expect(row).toContainText('Completed')

  const downloadPromise = page.waitForEvent('download')
  await row.getByRole('button', { name: 'Download' }).click()
  const download = await downloadPromise

  expect(download.suggestedFilename()).toMatch(/\.csv$/)
})
