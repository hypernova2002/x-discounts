import { describe, it, expect } from 'vitest'
import { coerce, attrsToObject, lineItemsToPayload } from './cartAttrs'

describe('coerce', () => {
  it('coerces "true"/"false" strings to real booleans', () => {
    expect(coerce('true')).toBe(true)
    expect(coerce('false')).toBe(false)
  })

  it('coerces numeric-looking strings to numbers', () => {
    expect(coerce('42')).toBe(42)
    expect(coerce('3.14')).toBe(3.14)
    expect(coerce('0')).toBe(0)
  })

  it('leaves an empty string as an empty string, not 0', () => {
    expect(coerce('')).toBe('')
  })

  it('leaves non-numeric, non-boolean strings untouched', () => {
    expect(coerce('gold')).toBe('gold')
    expect(coerce('JFK-LHR')).toBe('JFK-LHR')
  })
})

describe('attrsToObject', () => {
  it('builds an object from key/value pairs, coercing values', () => {
    expect(
      attrsToObject([
        { key: 'tier', value: 'gold' },
        { key: 'vip', value: 'true' },
        { key: 'age', value: '30' },
      ]),
    ).toEqual({ tier: 'gold', vip: true, age: 30 })
  })

  it('skips pairs with no key', () => {
    expect(attrsToObject([{ key: '', value: 'ignored' }, { key: 'kept', value: '1' }])).toEqual({ kept: 1 })
  })

  it('returns an empty object for an empty array', () => {
    expect(attrsToObject([])).toEqual({})
  })
})

describe('lineItemsToPayload', () => {
  it('maps sku/quantity/unit_price and merges in coerced attrs', () => {
    const result = lineItemsToPayload([{ sku: 'SHIRT-M', quantity: '2', unit_price: '19.99', attrs: [{ key: 'color', value: 'blue' }] }])
    expect(result).toEqual([{ sku: 'SHIRT-M', quantity: 2, unit_price: 19.99, color: 'blue' }])
  })

  it('defaults an unparseable quantity/unit_price to 0', () => {
    const result = lineItemsToPayload([{ sku: 'X', quantity: '', unit_price: 'not-a-number', attrs: [] }])
    expect(result[0].quantity).toBe(0)
    expect(result[0].unit_price).toBe(0)
  })

  it('handles multiple line items independently', () => {
    const result = lineItemsToPayload([
      { sku: 'A', quantity: '1', unit_price: '10', attrs: [] },
      { sku: 'B', quantity: '2', unit_price: '20', attrs: [] },
    ])
    expect(result).toHaveLength(2)
    expect(result.map((li) => li.sku)).toEqual(['A', 'B'])
  })
})
