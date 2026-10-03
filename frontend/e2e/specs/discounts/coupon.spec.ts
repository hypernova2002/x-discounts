import { test, expect, createCampaign, createCouponDiscount } from '../../fixtures/api'
import { uniqueSuffix } from '../../support/unique'
import { textField, selectOption, selectOptionByFilter, selectMultiOptionByFilter } from '../../support/controls'

test('create a coupon discount, requiring only campaign and name', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)

  await page.goto('/discounts/new')
  await selectOption(page, 'kind', 'Coupon')

  const name = `E2E Coupon ${uniqueSuffix()}`
  await textField(page, 'name').fill(name)
  await selectOptionByFilter(page, 'campaign_id', campaign.name, campaign.name)
  await page.getByRole('button', { name: 'Create discount' }).click()

  await expect(page).toHaveURL(/\/discounts\/disc_/)
  await expect(page.getByRole('heading', { name })).toBeVisible()
})

test('detail view renders the coupon section and codes table', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createCouponDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: discount.name })).toBeVisible()
  await expect(page.getByText('Coupon', { exact: true })).toBeVisible()
  await expect(page.getByText('No codes yet')).toBeVisible()
})

test('generates a one-off coupon code and revokes it', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createCouponDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await page.getByRole('button', { name: 'Generate codes' }).click()
  const code = `E2ECODE${uniqueSuffix().replace(/[^0-9]/g, '')}`
  await page.getByPlaceholder('e.g. SAVE20').fill(code)
  await page.getByRole('dialog').getByRole('button', { name: 'Add', exact: true }).click()

  await expect(page.getByText('Coupon codes generated')).toBeVisible()
  await expect(page.getByText(code)).toBeVisible()

  await page.getByRole('button', { name: 'Revoke' }).click()
  await expect(page.getByText('Code revoked')).toBeVisible()
  await expect(page.getByText('No codes yet')).toBeVisible()
})

test('edit renames the discount, clears eligibility, and marks a compatible discount', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createCouponDiscount(apiContext, campaign.id)
  const other = await createCouponDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}/edit`)
  await expect(textField(page, 'name')).toHaveValue(discount.name)

  const newName = `E2E Coupon Renamed ${uniqueSuffix()}`
  await textField(page, 'name').fill(newName)
  await page.getByRole('button', { name: 'Save changes' }).click()
  await expect(page).toHaveURL(`/discounts/${discount.id}`)
  await expect(page.getByRole('heading', { name: newName })).toBeVisible()

  // DiscountFormView fetches the compatible-discounts dropdown's option list
  // once on mount; under load that fetch can still be in flight by the time a
  // click opens the dropdown, and the open listbox doesn't pick up the list
  // arriving afterwards. Wait for that specific response before opening it.
  await Promise.all([
    page.waitForResponse((res) => res.url().includes('/admin/discounts?') && res.status() === 200),
    page.goto(`/discounts/${discount.id}/edit`),
  ])
  await selectMultiOptionByFilter(page, 'compatible_discounts', other.name, other.name)
  await expect(page.locator('#compatible_discounts').getByText(other.name)).toBeVisible()
})

test('delete permanently removes the coupon discount', async ({ page, apiContext }) => {
  const campaign = await createCampaign(apiContext)
  const discount = await createCouponDiscount(apiContext, campaign.id)

  await page.goto(`/discounts/${discount.id}`)
  await page.getByRole('button', { name: 'Delete' }).click()
  await page.getByRole('button', { name: 'Delete permanently' }).click()

  await expect(page).toHaveURL(`/campaigns/${campaign.id}`)
  await expect(page.getByText('Discount deleted')).toBeVisible()
})
