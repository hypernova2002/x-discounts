// Shared by DiscountDetailView's "Test validation" section and OrderFormView's
// discount-redemption flow — both build a cart/line-item/customer payload for
// POST /api/v1/discounts/{validate,redeem} out of a KeyValueEditor-style array
// of { key, value } pairs, and previously duplicated this exact coercion logic.

// Freeform attribute values come in as strings from the UI — coerce "true"/
// "false"/numeric-looking strings to their real types so custom-attribute
// comparisons on the backend (e.g. a boolean or numeric condition) behave as
// the admin intends, not as a string comparison.
export function coerce(raw) {
  if (raw === 'true') return true
  if (raw === 'false') return false
  if (raw !== '' && !Number.isNaN(Number(raw))) return Number(raw)
  return raw
}

export function attrsToObject(attrs) {
  return attrs.reduce((acc, pair) => {
    if (pair.key) acc[pair.key] = coerce(pair.value)
    return acc
  }, {})
}

export function lineItemsToPayload(lineItems) {
  return lineItems.map((li) => ({
    sku: li.sku,
    quantity: Number(li.quantity) || 0,
    unit_price: Number(li.unit_price) || 0,
    ...attrsToObject(li.attrs),
  }))
}
