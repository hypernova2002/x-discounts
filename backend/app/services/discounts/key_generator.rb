# frozen_string_literal: true

module Discounts
  # Slugifies `name` into a project-unique key, appending -2, -3, etc. on collision —
  # same "friendly slug" pattern used everywhere from CMS post slugs to Shopify
  # handles. Only called when the caller didn't supply their own key; an explicit
  # key is left exactly as given (still validated/uniqueness-checked by Discount
  # itself).
  class KeyGenerator
    def self.generate(name:, project:)
      base = name.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      base = "discount" if base.blank?

      candidate = base
      suffix = 1
      while Discount.where(project_id: project.id, key: candidate).any?
        suffix += 1
        candidate = "#{base}-#{suffix}"
      end

      candidate
    end
  end
end
