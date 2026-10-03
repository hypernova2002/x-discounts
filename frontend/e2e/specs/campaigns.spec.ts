import { test, expect, createCampaign, createPromotionDiscount } from '../fixtures/api'
import { uniqueSuffix } from '../support/unique'
import { textField, toggleSwitch } from '../support/controls'

test('list shows an empty state for a search that matches nothing', async ({ page }) => {
  await page.goto('/campaigns')
  await page.getByPlaceholder('Search campaigns').fill(`no-such-campaign-${uniqueSuffix()}`)
  await expect(page.getByText('No results found')).toBeVisible()
})

test('list shows a created campaign and search finds it', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto('/campaigns')
  await page.getByPlaceholder('Search campaigns').fill(campaign.name)
  await expect(page.getByText(campaign.name)).toBeVisible()
})

test('create requires a name, then succeeds', async ({ page }) => {
  await page.goto('/campaigns')
  await page.getByRole('button', { name: 'New campaign' }).click()
  await expect(page).toHaveURL('/campaigns/new')

  await page.getByRole('button', { name: 'Create campaign' }).click()
  await expect(page.getByText('Name is required')).toBeVisible()
  await expect(page).toHaveURL('/campaigns/new')

  const name = `E2E Campaign ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await page.getByRole('button', { name: 'Create campaign' }).click()

  await expect(page).toHaveURL(/\/campaigns\/camp_/)
  await expect(page.getByRole('heading', { name })).toBeVisible()
})

test('edit updates the name and enabled toggle', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto(`/campaigns/${campaign.id}/edit`)
  // load() populates the form asynchronously after mount — wait for it,
  // otherwise filling+submitting races it and validates against blank state.
  await expect(textField(page, 'name')).toHaveValue(campaign.name)
  const newName = `E2E Campaign Renamed ${uniqueSuffix()}`
  await textField(page, 'name').fill(newName)
  await toggleSwitch(page, 'enabled').click()
  await page.getByRole('button', { name: 'Save changes' }).click()

  await expect(page).toHaveURL(`/campaigns/${campaign.id}`)
  await expect(page.getByRole('heading', { name: newName })).toBeVisible()
})

test('detail view renders its nested discounts table', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createPromotionDiscount(apiContext, campaign.id)

  await page.goto(`/campaigns/${campaign.id}`)
  await expect(page.getByRole('heading', { name: campaign.name })).toBeVisible()
  await expect(page.getByText(discount.name)).toBeVisible()
})
