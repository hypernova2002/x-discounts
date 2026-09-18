# frozen_string_literal: true

class Campaign < Sequel::Model
  PUBLIC_ID_PREFIX = "camp"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project
  one_to_many :discounts

  def validate
    super
    validates_presence %i[project_id name]
  end

  def active?(now = Time.now.utc)
    enabled && !archived && (valid_from.nil? || valid_from <= now) && (valid_until.nil? || now <= valid_until)
  end
end
