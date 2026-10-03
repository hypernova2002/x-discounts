import type { Locator, Page } from '@playwright/test'

// Helpers for interacting with the OpenVue-backed Base* controls (see
// frontend/src/components/base/*.vue). Several of them render a composite DOM
// structure where the `id` attribute lands on an outer wrapper rather than
// the actual interactive element (BasePassword, BaseInputNumber, BaseSelect,
// BaseMultiSelect) — these helpers hide that so specs can just say "the field
// with this id" the way its <label for> does. Many BaseSelect/BaseMultiSelect
// usages across this app have no id at all, only a placeholder — the
// select*/multiSelect* functions below take the trigger as a Locator so
// either `byId(...)` or `page.getByText(placeholder)` can be passed in.

// BaseInputText / BaseTextarea render the real <input>/<textarea> as the root
// element itself, so `id` already targets it directly.
export function textField(page: Page, id: string) {
  return page.locator(`#${id}`)
}

// BasePassword / BaseInputNumber nest a real OpenVue InputText for the actual
// <input> inside a wrapper div that carries the id.
export function innerInput(page: Page, id: string) {
  return page.locator(`#${id} input`)
}

// BaseToggleSwitch's root wrapper fully covers a same-sized, absolutely
// positioned (if invisible) native checkbox input, so clicking the wrapper
// itself toggles it.
export function toggleSwitch(page: Page, id: string) {
  return page.locator(`#${id}`)
}

function byId(page: Page, id: string): Locator {
  return page.locator(`#${id}`)
}

// BaseSelect/BaseMultiSelect render their option list in a Portal appended to
// <body>, not inside the trigger's own subtree — open it, then act on the
// globally-rendered listbox.
export async function selectOption(page: Page, trigger: Locator | string, optionText: string | RegExp) {
  await (typeof trigger === 'string' ? byId(page, trigger) : trigger).click()
  await page.getByRole('option', { name: optionText }).click()
}

export async function selectOptionByFilter(page: Page, trigger: Locator | string, filterText: string, optionText: string | RegExp) {
  await (typeof trigger === 'string' ? byId(page, trigger) : trigger).click()
  // The options list for these selects is fetched over the network (not a
  // static local array) — wait for it to actually render before filtering,
  // otherwise typing into the filter can race the fetch and search an
  // empty/stale list forever.
  await page.getByRole('option').first().waitFor()
  await page.getByRole('searchbox').fill(filterText)
  await page.getByRole('option', { name: optionText }).click()
}

// Same as selectOptionByFilter, but for BaseMultiSelect: picking an option
// doesn't close the overlay (multiple picks are expected), so this closes it
// explicitly once done.
export async function selectMultiOptionByFilter(page: Page, trigger: Locator | string, filterText: string, optionText: string | RegExp) {
  await (typeof trigger === 'string' ? byId(page, trigger) : trigger).click()
  await page.getByRole('option').first().waitFor()
  await page.getByRole('searchbox').fill(filterText)
  await page.getByRole('option', { name: optionText }).click()
  await page.keyboard.press('Escape')
}
