# frozen_string_literal: true

require "tzinfo"

class Project < Sequel::Model
  PUBLIC_ID_PREFIX = "proj"
  # Full IANA identifier list (not ActiveSupport::TimeZone's ~150-entry curated
  # MAPPING) so this never rejects a zone the frontend's timezone picker offers
  # — that picker is built from Intl.supportedValuesOf('timeZone'), and
  # TZInfo's list is a confirmed superset of it.
  TIMEZONES = TZInfo::Timezone.all_identifiers.freeze

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :account
  one_to_many :project_memberships
  one_to_many :api_keys
  one_to_many :discounts
  one_to_many :customers
  one_to_many :custom_attributes
  one_to_many :orders
  one_to_many :campaigns
  one_to_many :membership_schemes
  one_to_many :gift_shop_items

  add_association_dependencies project_memberships: :destroy,
                                api_keys: :destroy,
                                discounts: :destroy,
                                customers: :destroy,
                                custom_attributes: :destroy,
                                orders: :destroy,
                                campaigns: :destroy,
                                membership_schemes: :destroy,
                                gift_shop_items: :destroy

  def validate
    super
    validates_presence [:name, :account_id]
    validates_unique %i[account_id name]
    validates_includes TIMEZONES, :timezone, allow_missing: true
  end
end
