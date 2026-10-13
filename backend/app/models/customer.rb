# frozen_string_literal: true

class Customer < Sequel::Model
  PUBLIC_ID_PREFIX = "cust"

  include PublicIdentifiable
  include BoundedFieldValidatable
  include Auditable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :project
  many_to_one :membership_tier
  one_to_many :redemptions
  one_to_many :orders
  one_to_many :loyalty_point_lots
  one_to_many :gift_shop_redemptions
  one_to_many :customer_activity_events

  add_association_dependencies redemptions: :destroy, orders: :destroy, loyalty_point_lots: :destroy,
                                gift_shop_redemptions: :destroy, customer_activity_events: :destroy

  def validate
    super
    validates_presence [:project_id, :external_id]
    validates_utf8_length :external_id, max: 255
    validates_unique [:project_id, :external_id] unless errors[:external_id]
    validates_utf8_length :name, max: 1000
    validates_utf8_length :email, max: 255
    validates_utf8_length :phone_number, max: 255
    validates_utf8_length :country, max: 255
    validates_boolean :marketing_opt_in
    errors.add(:date_of_birth, "cannot be in the future") if date_of_birth && date_of_birth > Date.today
  end

  # Sum of whatever's left in every non-expired lot — not earned-minus-redeemed
  # arithmetic, since a lot can become unspendable by expiring without ever being
  # redeemed. `now` is overridable so a validate-time preview can honor `as_of`;
  # RedeemService always calls this with the real clock. points_remaining is computed
  # (points + SUM(ledger delta)), so this sums both sides in one query rather than
  # calling LoyaltyPointLot#points_remaining per row.
  def loyalty_points_balance(now: Time.now.utc)
    valid_lot_ids = valid_lot_ids(now)
    return 0 if valid_lot_ids.empty?

    points_total = LoyaltyPointLot.where(id: valid_lot_ids).sum(:points) || 0
    debits_total = LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: valid_lot_ids).sum(:delta) || 0
    points_total + debits_total
  end

  # Spends from the oldest non-expired lots first (FIFO) — shared by both order-based
  # points redemption (Discounts::RedeemService) and gift shop redemption
  # (GiftShop::RedeemItemService), so there's exactly one implementation of "how
  # points actually get spent" to keep correct. Callers are expected to have already
  # locked this customer row (via #lock!) so concurrent spends can't race. spend_ref
  # is the PointsRedemption or GiftShopRedemption this spend is paying for — every
  # ledger entry traces back to it.
  def consume_loyalty_points!(points, spend_ref:, now: Time.now.utc)
    lots = loyalty_point_lots_dataset
           .where(Sequel.|({ expires_at: nil }, Sequel.lit("expires_at > ?", now)))
           .order(:earned_at)
           .all

    remaining = points
    lots.each do |lot|
      break if remaining <= 0

      lot_remaining = lot.points_remaining
      next if lot_remaining <= 0

      take = [lot_remaining, remaining].min
      LoyaltyPointLedgerEntry.create(
        loyalty_point_lot: lot,
        delta: -take,
        kind: "spend",
        points_redemption: spend_ref.is_a?(PointsRedemption) ? spend_ref : nil,
        gift_shop_redemption: spend_ref.is_a?(GiftShopRedemption) ? spend_ref : nil
      )
      remaining -= take
    end
  end

  # Reassigns the tier and records the transition as activity events — a
  # `membership_ended` for the tier being left (if any) and a `membership_started`
  # for the one being entered (if any) — so full tier history is reconstructable
  # from customer_activity_events, not just the current snapshot.
  def change_membership_tier!(new_tier, at: Time.now.utc)
    old_tier = membership_tier
    db.transaction do
      self.membership_tier = new_tier
      self.membership_tier_entered_at = new_tier ? at : nil
      save
      CustomerActivityEvent.record!(customer: self, type: "membership_ended", occurred_at: at, payload: tier_payload(old_tier)) if old_tier
      CustomerActivityEvent.record!(customer: self, type: "membership_started", occurred_at: at, payload: tier_payload(new_tier)) if new_tier
    end
    self
  end

  private

  def tier_payload(tier)
    { tier_name: tier.name, scheme_name: tier.membership_scheme.name }
  end

  def valid_lot_ids(now)
    loyalty_point_lots_dataset
      .where(Sequel.|({ expires_at: nil }, Sequel.lit("expires_at > ?", now)))
      .select_map(:id)
  end
end
