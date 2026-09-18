import { describe, it, expect } from 'vitest'
import { z } from 'zod'
import { toFieldErrors } from './formErrors'

describe('toFieldErrors', () => {
  it('maps a ZodError into { field: message }', () => {
    const schema = z.object({ name: z.string().min(1, 'Name is required') })
    const result = schema.safeParse({ name: '' })
    expect(toFieldErrors(result.error)).toEqual({ name: 'Name is required' })
  })

  it('maps a nested zod path (e.g. discriminated union sub-object) with dot notation', () => {
    const schema = z.object({ promotion: z.object({ active_from: z.string().min(1, 'Active from is required') }) })
    const result = schema.safeParse({ promotion: { active_from: '' } })
    expect(toFieldErrors(result.error)).toEqual({ 'promotion.active_from': 'Active from is required' })
  })

  it('maps a root-level zod refine (no path) to _root', () => {
    const schema = z.object({ a: z.string().optional(), b: z.string().optional() }).refine(() => false, { message: 'Pick exactly one' })
    const result = schema.safeParse({})
    expect(toFieldErrors(result.error)).toEqual({ _root: 'Pick exactly one' })
  })

  it('maps an ApiError-shaped object with structured field details', () => {
    const apiError = { details: [{ field: 'name', message: 'has already been taken' }] }
    expect(toFieldErrors(apiError)).toEqual({ name: 'has already been taken' })
  })

  it('maps an ApiError detail with field "base" to _root', () => {
    const apiError = { details: [{ field: 'base', message: 'something structural is wrong' }] }
    expect(toFieldErrors(apiError)).toEqual({ _root: 'something structural is wrong' })
  })

  it('falls back to _root for a plain message with no structured details', () => {
    expect(toFieldErrors({ message: 'Request failed with status 500' })).toEqual({ _root: 'Request failed with status 500' })
  })

  it('returns an empty object for an empty/unrecognized source', () => {
    expect(toFieldErrors({})).toEqual({})
  })
})
