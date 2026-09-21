import DOMPurify from 'dompurify'

// Client-side sanitization for the coupon design editor's live preview — the
// admin's HTML is already sanitized server-side on save (Coupons::HtmlSanitizer,
// via Loofah), but the preview renders whatever's currently typed, before
// anything has ever reached the backend, so it needs its own pass. This is the
// only place in the app that uses v-html, and only ever on this function's
// output. The allowed tags/attributes mirror the backend's intent: plain text
// and structure, images and links, no script/iframe/form/embedded content, no
// event-handler attributes.
const ALLOWED_TAGS = [
  'p', 'div', 'span', 'br', 'hr',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'strong', 'em', 'b', 'i', 'u', 'small', 'blockquote',
  'ul', 'ol', 'li',
  'a', 'img',
  'table', 'thead', 'tbody', 'tr', 'td', 'th',
]

const ALLOWED_ATTR = ['class', 'style', 'href', 'src', 'alt', 'title', 'width', 'height', 'target', 'rel']

export function sanitizeHtml(html) {
  if (!html) return ''
  return DOMPurify.sanitize(html, { ALLOWED_TAGS, ALLOWED_ATTR })
}
