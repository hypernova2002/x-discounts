# frozen_string_literal: true

class MembershipScheme < Sequel::Model
  PUBLIC_ID_PREFIX = "mscheme"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :project
  one_to_many :membership_tiers, order: :rank

  add_association_dependencies membership_tiers: :destroy

  def validate
    super
    validates_presence %i[project_id name]
  end
end
