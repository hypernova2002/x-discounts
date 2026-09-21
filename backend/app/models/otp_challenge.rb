# frozen_string_literal: true

require "securerandom"
require "digest"

# Issued after a password check succeeds for a user with OTP enabled, and destroyed once
# the OTP code is verified — bridges the gap between "password confirmed" and "session
# issued" without ever handing out a real Session token until the second factor passes.
class OtpChallenge < Sequel::Model
  TOKEN_PREFIX = "otpc"
  TTL = 10 * 60 # 10 minutes

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :user

  attr_reader :raw_token

  def self.create_for(user:)
    raw = "#{TOKEN_PREFIX}_#{SecureRandom.urlsafe_base64(32)}"

    challenge = new(user_id: user.id, token_digest: digest(raw), expires_at: Time.now.utc + TTL)
    challenge.instance_variable_set(:@raw_token, raw)
    challenge.save
    challenge
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.authenticate(raw_token)
    return nil unless raw_token

    challenge = first(token_digest: digest(raw_token))
    return nil unless challenge
    return nil if challenge.expired?

    challenge
  end

  def expired?
    expires_at < Time.now.utc
  end

  def consume!
    destroy
  end
end
