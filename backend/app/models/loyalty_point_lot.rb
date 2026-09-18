# frozen_string_literal: true

class LoyaltyPointLot < Sequel::Model
  PUBLIC_ID_PREFIX = "lot"

  SOURCES = %w[order manual_grant legacy_backfill redemption_refund].freeze
  STATUSES = %w[active expired cancelled].freeze

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :customer
  many_to_one :order
  many_to_one :discount
  many_to_one :refund_of_points_redemption, class: :PointsRedemption
  many_to_one :performed_by_user, class: :User
  one_to_many :ledger_entries, class: :LoyaltyPointLedgerEntry

  def validate
    super
    validates_presence %i[customer_id points earned_at source]
    validates_includes SOURCES, :source, allow_missing: true
  end

  def expired?(now = Time.now.utc)
    expires_at.present? && expires_at <= now
  end

  # A lot is a pure credit; every entry against it is a debit (spend or clawback),
  # so remaining is always points + SUM(delta) with delta stored negative. Computed
  # rather than a mutated column — see the loyalty_point_ledger_entries migration.
  def points_remaining
    points + (ledger_entries_dataset.sum(:delta) || 0)
  end

  # cancelled takes precedence over expired: a lot that lapsed and was later clawed
  # back (its earning order got refunded) reports the more specific fact. A lot
  # that's merely been fully spent stays 'active' — spending down to zero isn't a
  # lifecycle event the way a refund reversing the earn is.
  def status(now: Time.now.utc)
    return "cancelled" if ledger_entries_dataset.where(kind: "clawback").any?
    return "expired" if expired?(now)

    "active"
  end
end
