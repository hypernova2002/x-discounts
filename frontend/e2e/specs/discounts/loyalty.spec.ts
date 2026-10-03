import { test, expect, createCampaign, createLoyaltyDiscount } from '../../fixtures/api'
import { uniqueSuffix } from '../../support/unique'
import { textField, selectOption, selectOptionByFilter } from '../../support/controls'

test('create requires active from, then succeeds', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto('/discounts/new')
  await selectOption(page, 'kind', 'Loyalty points')

  const name = `E2E Loyalty ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await selectOptionByFilter(page, 'campaign_id', campaign.name, campaign.name)
  await page.getByRole('button', { name: 'Create discount' }).click()
  await expect(page.getByText('Active from is required')).toBeVisible()

  await textField(page, 'loyalty_active_from').fill('2026-01-01T00:00')
  await page.getByRole('button', { name: 'Create discount' }).click()

  await expect(page).toHaveURL(/\/discounts\/disc_/)
  await expect(page.getByRole('heading', { name })).toBeVisible()
})

test('detail view renders the loyalty section', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createLoyaltyDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: discount.name })).toBeVisible()
  await expect(page.getByText('Loyalty', { exact: true })).toBeVisible()
})

test('edit updates the name without a server error', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createLoyaltyDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}/edit`)
  await expect(textField(page, 'name')).toHaveValue(discount.name)

  const newName = `E2E Loyalty Renamed ${uniqueSuffix()}`
  await textField(page, 'name').fill(newName)
  await page.getByRole('button', { name: 'Save changes' }).click()

  await expect(page).toHaveURL(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: newName })).toBeVisible()
})

test('delete permanently removes the loyalty discount', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createLoyaltyDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await page.getByRole('button', { name: 'Delete' }).click()
  await page.getByRole('button', { name: 'Delete permanently' }).click()

  await expect(page).toHaveURL(`/campaigns/${campaign.id}`)
  await expect(page.getByText('Discount deleted')).toBeVisible()
})
