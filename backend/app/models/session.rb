# frozen_string_literal: true

require "securerandom"
require "digest"

class Session < Sequel::Model
  TOKEN_PREFIX = "sess"
  TTL = 30 * 24 * 60 * 60 # 30 days

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :user

  # Only ever available on the instance that generated it, same as ApiKey#raw_token.
  attr_reader :raw_token

  def self.create_for(user:)
    raw = "#{TOKEN_PREFIX}_#{SecureRandom.urlsafe_base64(32)}"

    session = new(user_id: user.id, token_digest: digest(raw), expires_at: Time.now.utc + TTL)
    session.instance_variable_set(:@raw_token, raw)
    session.save
    session
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.authenticate(raw_token)
    session = first(token_digest: digest(raw_token))
    return nil unless session
    return nil if session.expired?

    session.update(last_used_at: Time.now.utc)
    session
  end

  def expired?
    expires_at < Time.now.utc
  end
end
