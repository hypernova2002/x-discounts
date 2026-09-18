# frozen_string_literal: true

require "bcrypt"

class User < Sequel::Model
  PUBLIC_ID_PREFIX = "usr"
  # See frontend/src/i18n — each locale here needs a matching set of JSON files
  # under frontend/src/i18n/locales/<code>.
  LOCALES = %w[en ja].freeze

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

  private

  def validate_password
    return unless password

    errors.add(:password, "must be at least 8 characters") if password.length < 8
    errors.add(:password_confirmation, "doesn't match password") if password != password_confirmation
  end
end
