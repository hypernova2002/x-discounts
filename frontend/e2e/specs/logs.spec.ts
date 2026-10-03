import { test, expect, createCampaign } from '../fixtures/api'
import { selectOptionByFilter, selectOption } from '../support/controls'

// Self-contained: performs its own mutation via the API fixture and filters
// down to exactly that, rather than depending on other specs' leftovers
// (which would make this flaky under parallel execution).
test('filters down to a just-created campaign\'s audit log entry', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto('/logs')
  await selectOptionByFilter(page, page.getByText('Entity type', { exact: true }), 'Campaign', 'Campaign')
  await selectOption(page, page.getByText('Action', { exact: true }), 'Created')

  await expect(page.getByText(`Created Campaign "${campaign.name}"`)).toBeVisible()
})
