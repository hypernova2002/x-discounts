# frozen_string_literal: true

module Coupons
  # Server-side sanitization for a coupon's customer-facing design HTML — what
  # gets stored (and later returned by the API) is never the raw admin input.
  # Loofah's :strip scrubber (from rails-html-sanitizer, already a transitive
  # Rails dependency via actionview — no new gem needed) removes disallowed
  # elements/attributes (script tags, event-handler attributes, etc.) while
  # keeping their safe text content, rather than rejecting the whole submission.
  module HtmlSanitizer
    def self.sanitize(html)
      return nil if html.blank?

      Loofah.fragment(html).scrub!(:strip).to_s
    end
  end
end
