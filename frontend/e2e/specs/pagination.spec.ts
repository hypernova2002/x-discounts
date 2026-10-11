import { test, expect, createCampaign } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'

// Direct regression test for the bug this phase fixes: every list view used
// to fetch only the backend's default 25-row page and never ask for more, so
// anything past the 25th row was invisible with no indication more existed.
test('paginates across more than one page of real server data', async ({ page, apiContext }) => {
  const marker = `pg-${uniqueSuffix()}`
  for (let i = 0; i < 30; i++) {
    await createCampaign(apiContext, { name: `${marker} ${String(i).padStart(2, '0')}` })
  }

  await page.goto('/campaigns')
  await page.getByPlaceholder('Search campaigns').fill(marker)

  // Real total (30), not "however many happened to be on the loaded page".
  // Listed newest-first (Sequel.desc(:id)), so page 1 has the last 25
  // created (29 down to 5) and page 2 has the first 5 (04 down to 00).
  await expect(page.getByText('1 of 2')).toBeVisible()
  await expect(page.getByText(`${marker} 29`)).toBeVisible()
  await expect(page.getByText(`${marker} 00`)).not.toBeVisible()

  await page.getByRole('button', { name: 'Next page' }).click()

  // A bit more generous than the default 5s — this is a second real
  // server round-trip right after the search's own, and under parallel
  // load (the full suite, not this spec alone) that can occasionally
  // take a little longer.
  await expect(page.getByText('2 of 2')).toBeVisible({ timeout: 10000 })
  await expect(page.getByText(`${marker} 00`)).toBeVisible()
  await expect(page.getByText(`${marker} 29`)).not.toBeVisible()
})
