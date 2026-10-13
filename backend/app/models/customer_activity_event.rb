# frozen_string_literal: true

# An immutable log row for the customer-facing activity feed — one row per
# order placed, gift shop redemption, or membership tier start/end. `payload`
# is snapshotted at write time with whatever the feed needs to render that
# event, so reads never need to join back to the source tables.
class CustomerActivityEvent < Sequel::Model
  PUBLIC_ID_PREFIX = "cae"

  include PublicIdentifiable

  plugin :validation_helpers

  many_to_one :customer

  TYPES = %w[order gift_shop_redemption membership_started membership_ended].freeze

  def self.record!(customer:, type:, occurred_at:, payload: {})
    create(customer: customer, project_id: customer.project_id, type: type, occurred_at: occurred_at,
           payload: payload, created_at: Time.now.utc)
  end

  def validate
    super
    validates_presence %i[customer_id project_id type occurred_at]
    validates_includes TYPES, :type
  end
end
