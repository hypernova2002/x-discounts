# frozen_string_literal: true

require "securerandom"

# Assigns an opaque, prefixed public_id (e.g. "disc_a1b2c3...") on create — the
# only identifier the API ever exposes for this resource. The integer id stays
# purely internal (foreign keys, joins). Including class must define
# PUBLIC_ID_PREFIX.
module PublicIdentifiable
  def before_create
    self.public_id ||= "#{self.class::PUBLIC_ID_PREFIX}_#{SecureRandom.alphanumeric(16).downcase}"
    super
  end
end
