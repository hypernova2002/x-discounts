import { test, expect, createCampaign, createPromotionDiscount } from '../../fixtures/api'
import { uniqueSuffix } from '../../support/unique'
import { textField, selectOptionByFilter } from '../../support/controls'

test('create requires a campaign and name, then succeeds', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto('/discounts/new')
  await page.getByRole('button', { name: 'Create discount' }).click()
  await expect(page.getByText('Campaign is required')).toBeVisible()
  await expect(page.getByText('Name is required')).toBeVisible()

  const name = `E2E Promotion ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await selectOptionByFilter(page, 'campaign_id', campaign.name, campaign.name)
  await textField(page, 'active_from').fill('2026-01-01T00:00')
  await page.getByRole('button', { name: 'Create discount' }).click()

  await expect(page).toHaveURL(/\/discounts\/disc_/)
  await expect(page.getByRole('heading', { name })).toBeVisible()
})

test('detail view renders promotion-specific sections', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createPromotionDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: discount.name })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Promotion' })).toBeVisible()
  await expect(page.getByText('Active from')).toBeVisible()
})

test('edit updates the name and clears eligibility — regression check for the eligibility_condition update bug', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createPromotionDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}/edit`)
  // load() populates the form asynchronously after mount — wait for it,
  // otherwise filling+submitting races it and validates against blank state.
  await expect(textField(page, 'name')).toHaveValue(discount.name)
  const newName = `E2E Promotion Renamed ${uniqueSuffix()}`
  await textField(page, 'name').fill(newName)
  await page.getByRole('button', { name: 'Save changes' }).click()

  await expect(page).toHaveURL(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: newName })).toBeVisible()
  // A 500 here (NOT NULL eligibility_condition) would show an error toast
  // instead of landing back on the detail page — see backend/app/services/
  // promotions/update_service.rb.
  await expect(page.getByText('Something went wrong')).not.toBeVisible()
})

test('delete permanently removes the discount', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createPromotionDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await page.getByRole('button', { name: 'Delete' }).click()
  await page.getByRole('button', { name: 'Delete permanently' }).click()

  await expect(page).toHaveURL(`/campaigns/${campaign.id}`)
  await expect(page.getByText('Discount deleted')).toBeVisible()
})
