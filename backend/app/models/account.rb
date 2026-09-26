# frozen_string_literal: true

class Account < Sequel::Model
  PUBLIC_ID_PREFIX = "acct"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  one_to_many :users
  one_to_many :projects

  def validate
    super
    validates_presence :name
    validates_utf8_length :name, max: 1000
    validates_boolean :otp_required
  end
end
