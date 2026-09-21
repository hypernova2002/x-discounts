// @vitest-environment jsdom
//
// The rest of this suite runs under the faster `node` environment (see
// vite.config.js) since it's all pure-logic tests — but DOMPurify only
// self-initializes against a real DOM (it works directly in every real
// browser, which is the only place this function ever actually runs; in
// plain Node it exports an uninitialized factory instead), so this one file
// opts into jsdom rather than changing the environment for the whole suite.
import { describe, it, expect } from 'vitest'
import { sanitizeHtml } from './sanitizeHtml'

describe('sanitizeHtml', () => {
  it('strips script tags entirely', () => {
    const result = sanitizeHtml('<p>Hello</p><script>alert(1)</script>')
    expect(result).not.toContain('<script')
    expect(result).toContain('<p>Hello</p>')
  })

  it('strips event-handler attributes', () => {
    const result = sanitizeHtml('<img src="x.png" onerror="alert(1)">')
    expect(result).not.toContain('onerror')
    expect(result).toContain('src="x.png"')
  })

  it('strips iframes and forms', () => {
    expect(sanitizeHtml('<iframe src="evil.com"></iframe>')).not.toContain('<iframe')
    expect(sanitizeHtml('<form action="evil.com"><input></form>')).not.toContain('<form')
  })

  it('keeps allowed structural tags and attributes', () => {
    const result = sanitizeHtml('<div class="coupon"><strong>20% off</strong><a href="https://example.com">Shop</a></div>')
    expect(result).toContain('<div class="coupon">')
    expect(result).toContain('<strong>20% off</strong>')
    expect(result).toContain('href="https://example.com"')
  })

  it('returns an empty string for a falsy value', () => {
    expect(sanitizeHtml(null)).toBe('')
    expect(sanitizeHtml('')).toBe('')
    expect(sanitizeHtml(undefined)).toBe('')
  })
})
