# frozen_string_literal: true

require "securerandom"
require "digest"

class ApiKey < Sequel::Model
  TOKEN_PREFIX = "xdk"
  PUBLIC_ID_PREFIX = "key"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project
  many_to_one :user

  # Raw token is only ever available on the instance that generated it —
  # it is never persisted or derivable from the stored digest.
  attr_reader :raw_token

  def validate
    super
    validates_presence [:project_id, :user_id, :name, :role, :token_digest, :token_last_four]
    validates_includes ProjectMembership::ROLES, :role, allow_missing: true
  end

  def self.create_for(project:, user:, role:, name:)
    raw = "#{TOKEN_PREFIX}_#{SecureRandom.urlsafe_base64(32)}"

    key = new(
      project_id: project.id,
      user_id: user.id,
      role: role,
      name: name,
      token_digest: digest(raw),
      token_last_four: raw[-4..]
    )
    key.instance_variable_set(:@raw_token, raw)
    key.save
    key
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.authenticate(raw_token)
    key = first(token_digest: digest(raw_token))
    return nil unless key
    return nil if key.revoked?

    key.update(last_used_at: Time.now.utc)
    key
  end

  def revoked?
    !revoked_at.nil?
  end

  def revoke!
    update(revoked_at: Time.now.utc)
  end
end
