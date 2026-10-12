# frozen_string_literal: true

module Customers
  # Merges everything that's happened for a customer — orders, gift shop
  # redemptions, and their current membership tier entry — into one
  # chronologically-sorted feed, most recent first. Order-based points
  # earned/redeemed are shown as part of the order event they belong to rather
  # than as separate entries (that's what they already are structurally).
  class ActivityFeedService
    LIMIT = 100

    def initialize(customer:)
      @customer = customer
    end

    def call
      events = order_events + gift_shop_events + membership_events
      events.sort_by { |e| e[:occurred_at] }.reverse.first(LIMIT)
    end

    private

    # The true top-LIMIT across both streams can never need more than LIMIT
    # from either stream individually, so bounding each query here keeps this
    # capped regardless of the customer's lifetime order/redemption count —
    # only the already-small merged set gets sorted in Ruby below.
    #
    # Order#total_points_earned/#total_points_redeemed each issue their own
    # query when called per-order — bulk-compute both for the whole (now
    # bounded) batch instead, same shape as the resource bulk-stats services.
    def order_events
      orders = @customer.orders_dataset.order(Sequel.desc(:created_at)).limit(LIMIT).all
      order_ids = orders.map(&:id)

      points_earned_by_order = LoyaltyPointLot.where(order_id: order_ids, source: "order")
                                               .group(:order_id)
                                               .select(:order_id, Sequel.function(:sum, :points).as(:total))
                                               .to_hash(:order_id, :total)
      points_redeemed_by_order = PointsRedemption.where(order_id: order_ids).to_hash(:order_id, :points_redeemed)

      orders.map do |order|
        {
          type: "order",
          occurred_at: order.created_at,
          order_id: order.public_id,
          total_amount: order.total_amount.to_s,
          total_discount_amount: order.total_discount_amount.to_s,
          total_points_earned: (points_earned_by_order[order.id] || 0).to_i,
          total_points_redeemed: points_redeemed_by_order[order.id] || 0
        }
      end
    end

    def gift_shop_events
      @customer.gift_shop_redemptions_dataset.order(Sequel.desc(:redeemed_at)).limit(LIMIT).all.map do |redemption|
        {
          type: "gift_shop_redemption",
          occurred_at: redemption.redeemed_at,
          item_name: redemption.item_name,
          quantity: redemption.quantity,
          points_spent: redemption.points_spent
        }
      end
    end

    def membership_events
      return [] unless @customer.membership_tier && @customer.membership_tier_entered_at

      [{
        type: "membership",
        occurred_at: @customer.membership_tier_entered_at,
        tier_name: @customer.membership_tier.name,
        scheme_name: @customer.membership_tier.membership_scheme.name
      }]
    end
  end
end
