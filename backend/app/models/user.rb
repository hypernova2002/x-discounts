# frozen_string_literal: true

require "bcrypt"
require "rotp"
require "digest"
require "securerandom"

class User < Sequel::Model
  PUBLIC_ID_PREFIX = "usr"
  # See frontend/src/i18n — each locale here needs a matching set of JSON files
  # under frontend/src/i18n/locales/<code>.
  LOCALES = %w[en ja].freeze
  BACKUP_CODE_COUNT = 8

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :account
  one_to_many :project_memberships
  one_to_many :api_keys
  one_to_many :sessions

  add_association_dependencies project_memberships: :destroy, api_keys: :destroy, sessions: :destroy

  attr_accessor :password_confirmation
  attr_reader :password

  def password=(new_password)
    @password = new_password
    self.password_digest = BCrypt::Password.create(new_password).to_s if new_password.present?
  end

  def authenticate(candidate)
    return false unless password_digest

    BCrypt::Password.new(password_digest) == candidate
  end

  def validate
    super
    validates_presence [:email, :name, :account_id]
    validates_unique :email
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :email, message: "is not a valid email") if email
    validates_includes LOCALES, :locale, allow_missing: true
    validate_password
  end

  def otp_provisioning_uri
    ROTP::TOTP.new(otp_secret, issuer: "x-discounts").provisioning_uri(email)
  end

  def generate_otp_secret!
    update(otp_secret: ROTP::Base32.random)
  end

  def verify_otp(code)
    return false unless otp_secret

    ROTP::TOTP.new(otp_secret).verify(code.to_s.strip, drift_behind: 30, drift_ahead: 30).present? || consume_backup_code!(code)
  end

  def enable_otp!
    codes = Array.new(BACKUP_CODE_COUNT) { SecureRandom.hex(5) }
    update(otp_enabled: true, otp_backup_codes: codes.map { |c| Digest::SHA256.hexdigest(c) })
    codes
  end

  def disable_otp!
    update(otp_enabled: false, otp_secret: nil, otp_backup_codes: [])
  end

  private

  def consume_backup_code!(code)
    digest = Digest::SHA256.hexdigest(code.to_s.strip)
    return false unless otp_backup_codes.include?(digest)

    update(otp_backup_codes: otp_backup_codes - [digest])
    true
  end

  def validate_password
    return unless password

    errors.add(:password, "must be at least 8 characters") if password.length < 8
    errors.add(:password_confirmation, "doesn't match password") if password != password_confirmation
  end
end
