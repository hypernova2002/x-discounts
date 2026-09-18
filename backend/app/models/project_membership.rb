# frozen_string_literal: true

class ProjectMembership < Sequel::Model
  ROLES = %w[admin developer marketer viewer].freeze
  PUBLIC_ID_PREFIX = "memb"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project
  many_to_one :user

  def validate
    super
    validates_presence [:project_id, :user_id, :role]
    validates_includes ROLES, :role
    validates_unique [:project_id, :user_id]
  end
end
