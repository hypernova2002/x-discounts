// Mirrors the reserved, computed keys in backend/app/services/discounts/condition_evaluator.rb
// (cart_value) — these are never stored as CustomAttribute rows, so they need to be
// offered here explicitly rather than coming from the custom attributes API.
const RESERVED_CONDITION_KEYS = {
  cart: [
    { key: 'total', data_type: 'number' },
    { key: 'item_count', data_type: 'number' },
  ],
  customer: [
    { key: 'membership_tier', data_type: 'string' },
    { key: 'membership_scheme', data_type: 'string' },
  ],
}

export function reservedKeysFor(entity) {
  return RESERVED_CONDITION_KEYS[entity] || []
}
