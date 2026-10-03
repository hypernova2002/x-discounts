import { test, expect } from '@playwright/test'

test('renders the dashboard with stats and no console errors', async ({ page }) => {
  const errors: string[] = []
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(msg.text())
  })
  page.on('pageerror', (err) => errors.push(err.message))

  await page.goto('/')

  await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible()
  await expect(page.getByText('Total Revenue')).toBeVisible()
  await expect(page.getByText('Total Orders')).toBeVisible()
  await expect(page.getByText('Active Customers')).toBeVisible()

  expect(errors).toEqual([])
})
